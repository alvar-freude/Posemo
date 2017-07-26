#!/usr/bin/env perl

use strict;
use warnings;
use Test::PostgreSQL::Starter;
use Test::More;


#
# * pg_binary_ok($message)
# * pg_initdb_ok($name, $is_master, $initdb_params, $config, $message)
# * pg_initdb_unless_exists_ok($name, $is_master, $initdb_params, $config, $message)
# * pg_dropcluster_ok($name, $message)
# * pg_dropcluster_if_exists_ok($name, $message)
# * pg_start_ok($name, $message) (undef: all)
# * pg_stop_ok($name, $message) (undef: all)


pg_binary_ok();

pg_stop_if_running_ok("test");
pg_dropcluster_if_exists_ok("test", "Dropping an old cluster, if it exists.");

pg_initdb_ok("test");
pg_dropcluster_ok("test");

pg_initdb_unless_exists_ok("test", 1);

pg_start_ok("test");

sleep 2;
my $result = qx( psql -p 15432 postgres -c "SELECT 'Bingo' || 'Yeah';" );

like $result, qr(BingoYeah), "Query OK" or diag "Error with query; wrong result: '$result'";


done_testing();


