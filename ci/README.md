# What is here, and what is missing

`build.sh`, `apt-get.sh`, `fetch-verify.sh` and `msgpuck.sh` set up a build.

**There is no reload gate yet.** A reload test has to ask the module a
question only it can answer; for this module that means a Tarantool
instance to talk to over its msgpack-based binary protocol, so that has to
be written before the gate can exist. Until then the reload workflow is
absent rather than present and passing on something it does not check.
