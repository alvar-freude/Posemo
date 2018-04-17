#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use PostgreSQL::SecureMonitoring::Install;

plan skip_all => "Skip database initialisation because SKIP_INSTALL is set" if $ENV{SKIP_INSTALL};

my $TEST_AUTHOR = $ENV{RELEASE_TESTING} || $ENV{TEST_AUTHOR};


# plan tests => 7;


use Test::PostgreSQL::Starter;
my $host = pg_get_hostname("test");

my $install;

lives_ok sub {
   $install = PostgreSQL::SecureMonitoring::Install->new(
                                                          database         => "_posemo_tests",
                                                          user             => "_posemo_tests",
                                                          superuser        => "_posemo_superuser",
                                                          drop_database    => 0,
                                                          create_database  => 1,
                                                          create_superuser => 1,
                                                          create_user      => 1,
                                                          create_schema    => 1,
                                                          port             => 15432,
                                                          host             => $host,
                                                        );
   },
   "Got DB installer object";


BAIL_OUT("FATAL: Got no installation object, leaving.") unless $install;

ok( $install, "have monitoring installer object" );

lives_ok sub { $install->install_basics; }, "Installed basics (database)";


# Now DB and user accessible
my ( $dbh, $result );

lives_ok sub {
   $dbh = $install->dbh;
   ($result) = $dbh->selectrow_array("SELECT 'Connection OK';");
}, "Execute simple query";

is( $result, "Connection OK", "Have Database connection" );



lives_ok sub {
   $install->_do_create_user;
   $dbh->commit;
}, "Created monitoring user (for pgTAP connection)";

lives_ok sub {
   $install->_do_create_superuser;
   $dbh->commit;
}, "Created monitoring superuser";



lives_ok sub {
   $dbh->do("CREATE SCHEMA pgtap; SET search_path TO pgtap; CREATE EXTENSION pgtap; SET search_path TO DEFAULT;");
   $dbh->commit;
}, "pgTAP extention installed";


# Create another superuser, because the above created can NOT not login
# used for pgTAP checking when access to tables are needed
lives_ok sub {
   $dbh->do("CREATE USER _pgtap_superuser SUPERUSER;");
   $dbh->do("ALTER  USER _pgtap_superuser  SET search_path TO posemo, pgtap;");
   $dbh->do("ALTER  USER _posemo_superuser SET search_path TO posemo, pgtap;");
   $dbh->do("ALTER  USER _posemo_tests     SET search_path TO posemo, pgtap;");
   $dbh->do("GRANT  USAGE ON SCHEMA pgtap TO _posemo_tests;");
   $dbh->do("GRANT  USAGE ON SCHEMA pgtap TO _posemo_superuser;");
   $dbh->commit;
}, "my pgTAP superuser created and others prepared for testing";



done_testing();

