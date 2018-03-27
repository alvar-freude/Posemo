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
result_unit_is $result, "MB";


cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw(_posemo_tests postgres $TOTAL)], "Database names";
cmp_ok $result->{result}[0][1], '>', 5,  "Database _posemo tests is bigger then 5 MB";
cmp_ok $result->{result}[0][1], '<', 10, "Database _posemo tests is smaller then 10 MB";

is $result->{result}[0][1] + $result->{result}[1][1], $result->{result}[2][1], "Total size is the sum of the other both";




done_testing();

