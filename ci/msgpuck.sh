#!/bin/sh
#
# Build and install msgpuck where configure can find it.
#
# msgpuck has no Debian or Ubuntu package.  FreeBSD has devel/msgpuck, so
# there this is not needed and the script says so and does nothing.
#
#     ci/msgpuck.sh            installs into /usr/local
#     PREFIX=/tmp/x ci/msgpuck.sh
#
# The commit is pinned in .github/versions.env, like every other input.

set -eu

SRC=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=${PREFIX:-/usr/local}
WORK=${CI_WORK:-$SRC/ci-work}

if [ -e "$PREFIX/include/msgpuck.h" ] || [ -e /usr/include/msgpuck.h ] ||
   [ -e /usr/local/include/msgpuck/msgpuck.h ]; then
	echo "ci/msgpuck.sh: msgpuck is already here"
	exit 0
fi

PINS=$SRC/.github/versions.env
[ -r "$PINS" ] || { echo "ci/msgpuck.sh: cannot read $PINS" >&2; exit 1; }
# shellcheck source=../.github/versions.env
. "$PINS"

: "${MSGPUCK_COMMIT:?MSGPUCK_COMMIT is not set in $PINS}"
: "${MSGPUCK_SHA256:?MSGPUCK_SHA256 is not set in $PINS}"

mkdir -p "$WORK"
tarball=$WORK/msgpuck-$MSGPUCK_COMMIT.tar.gz

"$SRC/ci/fetch-verify.sh" \
	"https://codeload.github.com/rtsisyk/msgpuck/tar.gz/$MSGPUCK_COMMIT" \
	"$MSGPUCK_SHA256" "$tarball"

rm -rf "$WORK/msgpuck-$MSGPUCK_COMMIT"
tar xzf "$tarball" -C "$WORK"
cd "$WORK/msgpuck-$MSGPUCK_COMMIT"

# Its CMake install puts the header in include/msgpuck/ and a static
# library in lib/.  configure looks for <msgpuck.h>, so the header is
# placed where that finds it as well.
cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" . > "$WORK/msgpuck-cmake.log" 2>&1 ||
	{ tail -20 "$WORK/msgpuck-cmake.log"; exit 1; }
make > "$WORK/msgpuck-make.log" 2>&1 ||
	{ tail -20 "$WORK/msgpuck-make.log"; exit 1; }

sudo=
[ "$(id -u)" = 0 ] || sudo=sudo
$sudo make install > /dev/null
$sudo cp msgpuck.h "$PREFIX/include/msgpuck.h"

echo "ci/msgpuck.sh: installed into $PREFIX"
