# Changelog

## Unreleased

First release from this repository. It continues Tarantool's module, whose
history is intact here; their repository has had no commit since March
2021.

### Changed

- **yajl and msgpuck come from the system, always.** Upstream carried both
  as git submodules and preferred the bundled static libraries whenever
  they happened to be built. A release tarball never contains a submodule,
  so that path was only ever taken by someone building from a full clone,
  while every distribution — the FreeBSD port included — linked the system
  libraries. The submodules are gone and so is the second code path.
- `config` uses the `auto/module` form only, and refuses the build with a
  readable message when the two libraries are missing instead of failing
  later in the compile.
- `third_party/tp.h` moved to `src/`, which is the only file of that
  directory that was ever there.
- Dockerfile, docker-compose.yml, the top-level Makefile and the two
  example nginx.conf files are gone.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL and a FreeBSD run.
- `ci/msgpuck.sh`, which builds msgpuck from a pinned commit where no
  package exists. FreeBSD has `devel/msgpuck` and builds nothing.
- `t/00-directives.t` for what the directives accept and refuse, and that
  an unreachable database fails rather than taking the worker down.
