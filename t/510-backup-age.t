#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "BackupAge", "test";

no_warning_ok $result;
no_critical_ok $result;
name_is $result,        "Backup Age";
result_type_is $result, "integer";
row_type_is $result,    "single";
result_unit_is $result, "s";

result_is $result, undef, "No backup running";



done_testing();



