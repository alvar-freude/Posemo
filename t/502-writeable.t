#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "Writeable", "test";

no_warning_ok $result;
no_critical_ok $result;
name_is $result,        "Writeable";
result_type_is $result, "single";

result_cmp $result, "<", 1, "runtime of writeable check must be lower then 1 second";


done_testing();
