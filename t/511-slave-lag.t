#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "SlaveLag", "test";

no_warning_ok $result;
no_critical_ok $result;
name_is $result,        "Slave Lag";
result_type_is $result, "double precision";
row_type_is $result,    "single";
result_unit_is $result, "seconds";

result_is $result, undef, "Host is master";


# TODO: Check slave!


done_testing();



