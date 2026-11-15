# The directives parse, and the ones that are wrong are refused.
#
# There is no Tarantool instance here: its protocol is msgpack over a
# binary channel, and a stand-in for it has to be written before the
# proxying itself can be tested.  What is asked here is what nginx
# accepts, which is the part that breaks when the module meets a newer
# nginx.

use Test::Nginx::Socket 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: tnt_pass with an upstream block
--- http_config
    upstream tnt {
        server 127.0.0.1:3301;
    }
--- config
    location /t {
        tnt_pass tnt;
    }
    location /ok { return 200 "ok\n"; }
--- request
GET /ok
--- response_body
ok



=== TEST 2: the REST interface and its method list
--- http_config
    upstream tnt { server 127.0.0.1:3301; }
--- config
    location /t {
        tnt_pass                tnt;
        tnt_http_rest_methods   get post put delete;
        tnt_http_methods        all;
        tnt_method              "api";
        tnt_pass_http_request   on parse_args;
    }
    location /ok { return 200 "ok\n"; }
--- request
GET /ok
--- response_body
ok



=== TEST 3: buffers, timeouts and the upstream fallback
--- http_config
    upstream tnt { server 127.0.0.1:3301; }
--- config
    location /t {
        tnt_pass                     tnt;
        tnt_buffer_size              8k;
        tnt_in_multiplier            2;
        tnt_out_multiplier           2;
        tnt_connect_timeout          5s;
        tnt_read_timeout             30s;
        tnt_send_timeout             30s;
        tnt_next_upstream            error timeout;
        tnt_next_upstream_tries      2;
        tnt_next_upstream_timeout    10s;
        tnt_multireturn_skip_count   2;
    }
    location /ok { return 200 "ok\n"; }
--- request
GET /ok
--- response_body
ok



=== TEST 4: the space and index allow lists
--- http_config
    upstream tnt { server 127.0.0.1:3301; }
--- config
    location /t {
        tnt_pass            tnt;
        tnt_allowed_spaces  "users,sessions";
        tnt_allowed_indexes "primary,secondary";
    }
    location /ok { return 200 "ok\n"; }
--- request
GET /ok
--- response_body
ok



=== TEST 5: an unknown REST method is refused
--- http_config
    upstream tnt { server 127.0.0.1:3301; }
--- config
    location /t {
        tnt_pass              tnt;
        tnt_http_rest_methods nosuchmethod;
    }
--- must_die



=== TEST 6: a request without a backend fails, it does not crash
--- http_config
    upstream tnt { server 127.0.0.1:1; }
--- config
    location /t {
        tnt_pass            tnt;
        tnt_connect_timeout 1s;
        tnt_http_methods    all;
        tnt_method          "nothing";
    }
--- request
GET /t
--- error_code: 502
