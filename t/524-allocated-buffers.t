#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

my $result = result_ok "AllocatedBuffers", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "Allocated Buffers";
result_type_is $result, "bigint";
row_type_is $result,    "single";
result_unit_is $result, "buffers";
result_is_counter $result;


cmp_ok $result->{result}, '>', 0, "there are some allocated buffers";


# TODO:
# Do something and look if counter increases.

done_testing();

