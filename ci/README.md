# What is here, and what is missing

`build.sh`, `apt-get.sh`, `fetch-verify.sh` and `msgpuck.sh` set up a
build. `version.sh` holds the version in the sources against
`CHANGELOG.md`, which the lint workflow runs.

**There is no reload gate yet.** A reload test has to ask the module a
question only it can answer; for this module that means a Tarantool
instance to talk to over its msgpack-based binary protocol, so that has to
be written before the gate can exist. Until then the reload workflow is
absent rather than present and passing on something it does not check.

**And `t/` barely reaches the module.** Every request in the suite goes to
a location with `return 200`, except the one that asks for a 502 from an
unreachable database. `tp_transcode.c` and `json_encoders.c`, which are
the msgpack side, execute in none of them: valgrind and the sanitizers run
green over code they never enter. The Tarantool stand-in is what would
change that, so this is one piece of work and not two. Worth knowing when
reading the badges: they say the module builds clean and parses what it
should, not that its transcoding has been measured.
