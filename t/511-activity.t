#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;



my $result = result_ok "Activity", "test";

no_warning_ok $result;
no_critical_ok $result;
name_is $result,        "Activity";
result_type_is $result, "integer";
row_type_is $result,    "multiline";
result_unit_is $result, "";

result_is $result,
   [ [ '!TOTAL', 1, 0, 0, 0, 0, 0, ], [ "_posemo_tests", 1, 0, 0, 0, 0, 0, ], [ "postgres", 0, 0, 0, 0, 0, 0, ], ],
   "Activity as expected";



done_testing();

