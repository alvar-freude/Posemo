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

pg_dropcluster_if_exists_ok("test", "Dropping an old cluster, if it exists.");

pg_initdb_ok("test");
pg_dropcluster_ok("test");

pg_initdb_unless_exists_ok("test", 1);

pg_start_ok("test");

sleep 2;
my $result = qx( psql -p 15432 postgres -c "SELECT 'Bingo' || 'Yeah';" );

like $result, qr(BingoYeah), "Query OK" or diag "Error with query; wrong result: '$result'";
#
#
#$result = qx( psql -p 15432 postgres -c "CREATE USER postgres SUPERUSER;" );
#like $result, qr( ( CREATE\s+(USER|ROLE) | ) )x, "User postgres installed" or diag "Error with query; wrong result: '$result'";
#
#$result = qx( psql -p 15432 postgres -c "CREATE USER _posemo_tests;" );
#like $result, qr(CREATE (USER|ROLE)), "User _posemo_tests installed" or diag "Error with query; wrong result: '$result'";
#
##$result = qx( psql -p 15432 postgres -c "CREATE USER _posemo_tests;" );
##like $result, qr(CREATE (USER|ROLE)), "User _posemo_tests installed" or diag "Error with query; wrong result: '$result'";
#
#$result = qx( psql -p 15432 postgres -c "CREATE DATABASE _posemo_tests OWNER _posemo_tests;" );
#like $result, qr(CREATE DATABASE), "Database _posemo_tests installed" or diag "Error with query; wrong result: '$result'";

#$result = qx( psql -p 15432 _posemo_tests -c "CREATE EXTENSION pgtap;" );
#like $result, qr(CREATE EXTENSION), "Extension pgtap installed" or diag "Error with query; wrong result: '$result'";


done_testing();


