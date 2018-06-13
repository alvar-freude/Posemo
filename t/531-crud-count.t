#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

use Test::Deep;


my $result = result_ok "CRUDCount", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "CRUD Count";
result_type_is $result, "bigint";
row_type_is $result,    "multiline";
result_unit_is $result, "";
result_is_counter $result;

cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw( $TOTAL _posemo_tests postgres )], "Database names";

cmp_ok $result->{result}[1][1], '>', 1000, "Database _posemo_tests some returned rows";
cmp_ok $result->{result}[1][2], '>', 1000, "Database _posemo_tests some fetched rows";
cmp_ok $result->{result}[1][3], '>', 1000, "Database _posemo_tests some inserted rows";
cmp_ok $result->{result}[1][4], '>', 10,   "Database _posemo_tests some updated rows";
cmp_ok $result->{result}[1][5], '>', 0,    "Database _posemo_tests some deleted rows";


for my $col ( 1 .. 5 )
   {
   is $result->{result}[1][1] + $result->{result}[2][1], $result->{result}[0][1], "Sum col $col is same as TOTAL";
   }


# TODO: do some work and look into counters ...


done_testing();

