#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

my $result = result_ok "ConnectionLimit", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "Connection Limit";
result_type_is $result, "real";
row_type_is $result,    "single";
result_unit_is $result, "%";
result_isnt_counter $result;


cmp_ok $result->{result}, '>', 0,  "More then 0% connections used";
cmp_ok $result->{result}, '<', 50, "Fewer then 50% connections used";


# TODO:
# Do something and look if counter increases.

done_testing();

