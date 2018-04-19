#!/usr/bin/env perl

use strict;
use warnings;
use Test::PostgreSQL::Starter;
use Test::More;


pg_binary_ok();

pg_stop_if_running_ok("test");
pg_dropcluster_if_exists_ok( "test", "Dropping an old cluster, if it exists." );

pg_initdb_ok("test");
pg_dropcluster_ok("test");

pg_initdb_unless_exists_ok( "test", 1 );

pg_start_ok("test");
pg_wait_started_ok("test");


# Delete other search paths, because Debian/Ubuntu psql wrapper is junk (using system perl)
# and travis sets his own perl library search path.
delete $ENV{PERL5LIB};
delete $ENV{PERLLIB};
my $host   = pg_get_hostname("test");
my $result = qx( psql -h $host -p 15432 postgres -c "SELECT 'Bingo' || 'Yeah';" );

like $result, qr(BingoYeah), "Query OK" or do
   {
   diag "Error with simple test query; wrong result: '$result'";
   pg_diag_logs("test");
   };

done_testing();


