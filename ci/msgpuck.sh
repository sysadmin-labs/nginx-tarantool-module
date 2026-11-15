#!/bin/sh
#
# Build and install msgpuck where nginx's configure can find it.
#
# msgpuck has no Debian or Ubuntu package.  FreeBSD has devel/msgpuck, so
# there this is not needed: the script finds the header already in place
# and does nothing.
#
#     ci/msgpuck.sh                installs into /usr/local
#     PREFIX=/opt/x ci/msgpuck.sh
#
# The commit is pinned in .github/versions.env, like every other input.
#
# Built by hand rather than through its CMakeLists.txt: the library is two
# translation units and one header, so cmake would be a build dependency
# for nothing -- and one that is not on every runner.

set -eu

SRC=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=${PREFIX:-/usr/local}
WORK=${CI_WORK:-$SRC/ci-work}

for h in "$PREFIX/include/msgpuck.h" /usr/include/msgpuck.h \
         /usr/local/include/msgpuck.h; do
	if [ -e "$h" ]; then
		echo "ci/msgpuck.sh: already here, $h"
		exit 0
	fi
done

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

CC=${CC:-cc}

# -fPIC: the nginx module this is linked into can be a loadable object.
echo "--- building msgpuck ---"
$CC -c -fPIC -O2 -std=c99 msgpuck.c hints.c
ar rcs libmsgpuck.a msgpuck.o hints.o

sudo=
[ "$(id -u)" = 0 ] || sudo=sudo
[ -w "$PREFIX/lib" ] && [ -w "$PREFIX/include" ] && sudo=

$sudo mkdir -p "$PREFIX/lib" "$PREFIX/include"
$sudo cp libmsgpuck.a "$PREFIX/lib/"
$sudo cp msgpuck.h "$PREFIX/include/"

echo "ci/msgpuck.sh: installed into $PREFIX"
