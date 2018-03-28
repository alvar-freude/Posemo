#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

use Test::Deep;


my $result = result_ok "CacheHitRatio", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "Cache Hit Ratio";
result_type_is $result, "real";
row_type_is $result,    "multiline";
result_unit_is $result, "%";

cmp_deeply [ map { $_->[0] } @{ $result->{result} } ], [qw( $TOTAL _posemo_tests postgres )], "Database names";

for my $idx ( 0 .. 2 )
   {
   cmp_ok $result->{result}[$idx][1], '>', 80,  "Database $result->{result}[$idx][0] has more then 80% cache hit rate";
   cmp_ok $result->{result}[$idx][1], '<', 100, "Database $result->{result}[$idx][0] has fewer then 100% cache hit rate";
   }

# re-check critical/warning with warning

$result = result_ok "CacheHitRatio", "test", { warning_level => 98, critical_level => 99, };

no_error_ok $result;
warning_ok $result;
critical_ok $result;


done_testing();
