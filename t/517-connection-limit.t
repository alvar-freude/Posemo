#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;
use Test::PostgreSQL::Starter;

use PostgreSQL::SecureMonitoring::Checks qw(:status);


plan tests => 139;

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
cmp_ok $result->{result}, '<', 10, "Fewer then 10% connections used";


my $conf = pg_read_conf_ok("test");

my @conns;

push @conns, get_connection_ok($conf) for 1 .. 50;

# now we have 51 connections; recheck
$result = result_ok "ConnectionLimit", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
status_is $result, STATUS_OK;


cmp_ok $result->{result}, '>', 45, "More then 45% connections used";
cmp_ok $result->{result}, '<', 55, "Fewer then 55% connections used";


push @conns, get_connection_ok($conf) for 1 .. 25;


# now we have 76 connections; recheck
$result = result_ok "ConnectionLimit", "test";

warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
status_is $result, STATUS_WARNING;


cmp_ok $result->{result}, '>', 75, "More then 75% connections used";
cmp_ok $result->{result}, '<', 80, "Fewer then 80% connections used";


push @conns, get_connection_ok($conf) for 1 .. 15;


# now we have 91 connections; recheck
$result = result_ok "ConnectionLimit", "test";

warning_ok $result;
critical_ok $result;
no_error_ok $result;
status_is $result, STATUS_CRITICAL;


cmp_ok $result->{result}, '>', 90, "More then 90% connections used";
cmp_ok $result->{result}, '<', 95, "Fewer then 95% connections used";



done_testing();

