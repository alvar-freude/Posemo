#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;


my $result = result_ok "IsMaster", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Is Master";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# Next check, need master
$result = result_ok "IsMaster", "test", { master_required => 1, };

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Is Master";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# Next check, need slave
$result = result_ok "IsMaster", "test", { slave_required => 1, };

no_warning_ok $result;
critical_ok $result;
no_error_ok $result;
message_like $result,   qr{^Failed.*not a slave};
name_is $result,        "Is Master";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# TODO:
# Start slave and check against it.


done_testing();



