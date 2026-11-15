# nginx-tarantool-module

[![Build][build-test-badge]][build-test-link]
[![Lint][lint-badge]][lint-link]
[![CodeQL][codeql-badge]][codeql-link]
[![A/UBSan][sanitizers-badge]][sanitizers-link]
[![Valgrind][valgrind-badge]][valgrind-link]
[![FreeBSD][freebsd-badge]][freebsd-link]

[build-test-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/build-test.yml/badge.svg
[build-test-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/build-test.yml
[lint-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/lint.yml/badge.svg
[lint-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/lint.yml
[codeql-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/codeql.yml/badge.svg
[codeql-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/codeql.yml
[sanitizers-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/sanitizers.yml/badge.svg
[sanitizers-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/sanitizers.yml
[valgrind-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/valgrind.yml/badge.svg
[valgrind-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/valgrind.yml
[freebsd-badge]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/freebsd.yml/badge.svg
[freebsd-link]: https://github.com/sysadmin-labs/nginx-tarantool-module/actions/workflows/freebsd.yml

Talk to a Tarantool database from nginx over its own binary protocol, and
expose it as a REST or JSON-RPC endpoint. nginx translates between JSON on
the HTTP side and msgpack on the database side, so a stored procedure can
be called without a layer in between.

## Where this comes from

Tarantool's own module, continued here with its history intact. Their
repository has had no commit since March 2021, carries 29 open issues, and
the FreeBSD port builds from it.

**Changed here:** yajl and msgpuck come from the system, always. Upstream
carried both as git submodules and preferred the bundled static libraries
whenever they happened to be built — but a release tarball never contains a
submodule, so that path was only ever taken by someone building from a full
clone, while every distribution, the FreeBSD port included, linked the
system libraries. The submodules are gone and there is one way in rather
than two that behave differently.

**Also changed:** three one-bit bit-fields are unsigned now. Declared as
`ngx_int_t` they could not hold the 1 assigned to them, it became -1, and
clang refuses that under `-Werror` -- so the module did not build on
FreeBSD at all. Every read is a truth test, so nothing behaved
differently; a later `== 1` would have.

What is new besides that is the scaffolding: a build against the releases the ports ship, the
sanitizers, valgrind, CodeQL and a FreeBSD run. There is no reload gate
yet, and `ci/README.md` says why.

## Requirements

nginx 1.28 or newer, libyajl and msgpuck.

On FreeBSD both are ports: `devel/yajl` and `devel/msgpuck`. On Debian and
Ubuntu yajl is `libyajl-dev`; msgpuck has no package, and `ci/msgpuck.sh`
builds it from a pinned commit.

## Building

```sh
./configure --add-module=/path/to/nginx-tarantool-module
```

As a loadable module, `--add-dynamic-module=` and then

```nginx
load_module modules/ngx_http_tnt_module.so;
```

## Quick start

```nginx
upstream tnt {
    server 127.0.0.1:3301 max_fails=1 fail_timeout=60s;
    keepalive 16;
}

server {
    location /tnt {
        tnt_pass tnt;
    }

    # the REST form: the method comes from the path
    location /api/ {
        tnt_http_rest_methods get post put delete;
        tnt_pass_http_request on parse_args;
        tnt_pass tnt;
    }
}
```

The JSON-RPC form posts `{"method": "...", "params": [...], "id": 1}` to
the first location. The REST form takes the method from the request path,
so `GET /api/myfunc` calls `myfunc`.

## Directives

The full set is in upstream's reference, kept as `README.md` history and
in the module's own documentation. The ones that decide the shape:

|Directive|What it decides|
|---|---|
|`tnt_pass`|the Tarantool upstream|
|`tnt_http_methods`|which HTTP methods reach the JSON-RPC form|
|`tnt_http_rest_methods`|which reach the REST form|
|`tnt_method`|a fixed method name, so the client does not choose|
|`tnt_pass_http_request`|what of the request is handed over: `parse_args`, `parse_urlencoded`, `pass_body`, `pass_headers_out`, `pass_subrequest_uri`|
|`tnt_allowed_spaces`, `tnt_allowed_indexes`|the spaces and indexes a client may name|
|`tnt_multireturn_skip_count`|how much of a multi-value return to drop|
|`tnt_buffer_size`, `tnt_in_multiplier`, `tnt_out_multiplier`|the buffers the transcoder works in|

`tnt_allowed_spaces` and `tnt_allowed_indexes` are worth setting whenever
a client can name a space itself.

## Testing

```sh
ci/msgpuck.sh                       # where msgpuck has no package
ci/build.sh 1.30.6 /tmp/nginx-test
TEST_NGINX_BINARY=/tmp/nginx-test/sbin/nginx prove -r t/
```

The suite does not talk to a database: Tarantool's protocol is msgpack over
a binary channel, and a stand-in has to be written before that can be
tested. What it asks is what nginx accepts — the part that breaks when the
module meets a newer nginx — that the wrong configurations are refused, and
that a request to an unreachable database fails rather than taking the
worker down.

## License

BSD 2-Clause. See `LICENSE`.
