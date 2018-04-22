#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "Primary", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Primary";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# Next check, need master
$result = result_ok "Primary", "test", { is_primary => 1, };

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Primary";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# Next check, need slave
$result = result_ok "Primary", "test", { isnt_primary => 1, };

no_warning_ok $result;
critical_ok $result;
no_error_ok $result;
message_like $result,   qr{^Failed.*it is a primary};
name_is $result,        "Primary";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# TODO:
# Start slave and check against it.


done_testing();



