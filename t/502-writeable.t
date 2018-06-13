#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "Writeable", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Writeable";
result_type_is $result, "float";
row_type_is $result,    "single";

result_cmp $result, "<", 1, "runtime of writeable check must be lower then 1 second";


# Check for a connection error
$result = result_ok "Writeable", "test", { }, { port => 5999 };
error_ok $result;



#
# TODO: check writeable for Master/Slave, async and sync.
#       => Start Master/Slave and run check ...


done_testing();



