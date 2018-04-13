#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::PostgreSQL::SecureMonitoring;

use Test::Deep;


my $result = result_ok "CheckpointTime", "test";

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;

name_is $result,        "Checkpoint Time";
result_type_is $result, "double precision";
row_type_is $result,    "list";
result_unit_is $result, "ms";
result_is_counter $result;


is scalar @{ $result->{result} }, 2, "Result has two columns";

cmp_ok $result->{result}[0], '>', 0, "write_time is more then 0 milliseconds";

# the sync time is usually 0, but don't check, because it depends on environment!
# cmp_ok $result->{result}[1], '>', 0, "sync_time is more then 0 milliseconds";


done_testing();

