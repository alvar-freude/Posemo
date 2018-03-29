#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

use Test::Deep;


my $result = result_ok "Transactions", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "Transactions";
result_type_is $result, "bigint";
row_type_is $result,    "multiline";
result_unit_is $result, "";
result_is_counter $result;

cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw( $TOTAL _posemo_tests postgres )], "Database names";
cmp_ok $result->{result}[1][1], '>', 5,    "Database _posemo_tests has more then 5 committed transactions";
cmp_ok $result->{result}[1][1], '<', 1000, "Database _posemo_tests has fewer then 1000 committed transactions";

is $result->{result}[1][1] + $result->{result}[2][1], $result->{result}[0][1],
   "Sum of committed transactions is the same as TOTAL";
is $result->{result}[1][2] + $result->{result}[2][2], $result->{result}[0][2],
   "Sum of rollbacked transactions is the same as TOTAL";

# TODO: do some transactions and look into count ...


done_testing();

