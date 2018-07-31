#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

use Test::Deep;


my $result = result_ok "DBSize", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "DB Size";
result_type_is $result, "integer";
row_type_is $result,    "multiline";
result_unit_is $result, "bytes";


cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw(!TOTAL _posemo_tests postgres)], "Database names";
cmp_ok $result->{result}[1][1], '>', 5*1024*1024,  "Database _posemo tests is bigger then 5 MB";
cmp_ok $result->{result}[1][1], '<', 10*1024*1024, "Database _posemo tests is smaller then 10 MB";

is $result->{result}[1][1] + $result->{result}[2][1], $result->{result}[0][1], "Total size is the sum of the other both";




done_testing();

