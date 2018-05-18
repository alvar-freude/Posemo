#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "Alive", "test";

no_warning_ok $result;
no_critical_ok $result;
name_is $result,        "Alive";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";

# get result with wrong port.
$result = result_ok "Alive", "test", {}, { port => 5999 };

message_like $result, qr{^Failed Alive check}, "Message for failed alive check";
no_warning_ok $result;
critical_ok $result;
name_is $result,        "Alive";
result_is $result,      0;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# get result with wrong port, but no critical, warn instead.
$result = result_ok "Alive", "test", { no_critical => 1, warn_if_failed => 1, }, { port => 5999 };

message_like $result, qr{^Failed Alive check}, "Message for failed alive check";
warning_ok $result;
no_critical_ok $result;
name_is $result,        "Alive";
result_is $result,      0;
row_type_is $result,    "single";
result_type_is $result, "boolean";



done_testing();



