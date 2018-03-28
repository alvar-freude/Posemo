#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;
use Test::PostgreSQL::Starter;
use Test::Deep;
use Test::Exception;

plan tests => 220;


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

my $transcount_total          = $result->{result}[0][1];
my $transcount                = $result->{result}[1][1];
my $transcount_pg             = $result->{result}[2][1];
my $transcount_rollback_total = $result->{result}[0][2];

cmp_ok $transcount, '>', 5,    "Database _posemo_tests has more then 5 committed transactions";
cmp_ok $transcount, '<', 1000, "Database _posemo_tests has fewer then 1000 committed transactions";

is $transcount + $transcount_pg, $transcount_total, "Sum of committed transactions is the same as TOTAL";
is $result->{result}[1][2] + $result->{result}[2][2], $result->{result}[0][2],
   "Sum of rollbacked transactions is the same as TOTAL";


# do some transactions and look into count ...

my $conf = pg_read_conf_ok("test");
my $dbh = get_connection_ok( $conf, undef, 1 );

my $expected_total    = $transcount_total + 1;
my $expected          = $transcount + 1;
my $expected_pg       = $transcount_pg;
my $expected_rollabck = $transcount_rollback_total;

#
# Test if tracactions increase; sometimes, they increase more then used here,
# therefore check for greater or equal expected!
#

for my $testnum ( 1 .. 10 )
   {
   my $writeable = result_ok "Writeable", "test", undef, undef, "Write check Nr. $testnum";
   no_warning_ok $writeable,  "Writing Nr. $testnum no warning";
   no_critical_ok $writeable, "Writing Nr. $testnum no critical";
   no_error_ok $writeable,    "Writing Nr. $testnum no error";

<<<<<<< HEAD
   sleep 1;                                        # Sleep a little bit, PG needs some time to update

   my $result = result_ok "Transactions", "test", undef, undef, "Transaction Test Nr. $testnum";
   no_warning_ok $result,  "Transaction Counter Nr. $testnum no warning";
   no_critical_ok $result, "Transaction Counter Nr. $testnum no critical";
   no_error_ok $result,    "Transaction Counter Nr. $testnum no error";

   cmp_ok $result->{result}[0][1], ">=", $expected_total, "Total Transaction counter increased (expected: $expected_total)";
   cmp_ok $result->{result}[1][1], ">=", $expected,       "My Test DB Transaction counter increased (expected: $expected)";
   cmp_ok $result->{result}[0][2], ">=", $expected_rollabck, "Rollback increased (Nr. $testnum)";
   is $result->{result}[2][1], $expected_pg, "PG DB Transaction counter not increased (Nr $testnum).";

   $expected_total    = $result->{result}[0][1] + 1;
   $expected          = $result->{result}[1][1] + 1;
   $expected_rollabck = $result->{result}[0][2] + 1;
=======
cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw( $TOTAL _posemo_tests postgres )], "Database names";
cmp_ok $result->{result}[1][1], '>', 5,  "Database _posemo_tests has more then 5 committed transactions";
cmp_ok $result->{result}[1][1], '<', 1000, "Database _posemo_tests has fewer then 1000 committed transactions";

is $result->{result}[1][1] + $result->{result}[2][1], $result->{result}[0][1], "Sum of committed transactions is the same as TOTAL";
is $result->{result}[1][2] + $result->{result}[2][2], $result->{result}[0][2], "Sum of rollbacked transactions is the same as TOTAL";

# TODO: do some transactions and look into count ...
>>>>>>> 650436d... $TOTAL first row in multiline checks

   } ## end for my $testnum ( 1 .. ...)

done_testing();

