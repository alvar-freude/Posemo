#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use Test::PostgreSQL::SecureMonitoring;

use PostgreSQL::SecureMonitoring::Install;


plan tests => 38;

use Test::PostgreSQL::Starter;
my $host = pg_get_hostname("test");

my $conf = pg_read_conf_ok("test");

my $install;

lives_ok sub {
   $install = PostgreSQL::SecureMonitoring::Install->new(
                                                          database         => "extratest",
                                                          user             => "extratest",
                                                          superuser        => "extratest_admin",
                                                          create_user      => 1,
                                                          create_superuser => 1,
                                                          create_database  => 1,
                                                          create_schema    => 1,
                                                          drop_schema      => 1,
                                                          port             => $conf->{port},
                                                          host             => $host,
                                                        );
   },
   "survive installer object creation";


BAIL_OUT("FATAL: No install object, leaving") unless $install;

ok( $install, "have monitoring installer object" );

lives_ok sub {
   $install->install;
}, "Extratest installation complete";


my $result = result_ok "Alive", "test", undef, { database => "extratest", user => "extratest", };

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Alive";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";


# Close other connection, which is cached! ...
pg_stop_ok("test");
pg_start_ok("test");


#
# Again, with drop DB and schame "public
#

lives_ok sub {
   $install = PostgreSQL::SecureMonitoring::Install->new(
                                                          database         => "extratest",
                                                          user             => "extratest",
                                                          superuser        => "extratest_admin",
                                                          schema           => "public",
                                                          create_user      => 1,
                                                          create_superuser => 1,
                                                          create_database  => 1,
                                                          create_schema    => 1,
                                                          drop_database    => 1,
                                                          drop_user        => 1,
                                                          port             => $conf->{port},
                                                          host             => $host,
                                                        );
}, "survive installer object creation";


BAIL_OUT("FATAL: No install object, leaving") unless $install;

ok( $install, "have monitoring installer object" );

lives_ok sub {
   $install->install;
}, "Extratest installation complete";


$result = result_ok "Alive", "test", undef, { database => "extratest", user => "extratest", schema => "public", };

no_warning_ok $result;
no_critical_ok $result;
no_error_ok $result;
name_is $result,        "Alive";
result_is $result,      1;
row_type_is $result,    "single";
result_type_is $result, "boolean";



pg_stop_ok("test");
pg_start_ok("test");


my $dbh = get_connection_ok( $conf, undef, 1 );
$dbh->{AutoCommit} = 1;                            # disable transaction for deleting database.

lives_ok sub { ok $dbh->do("DROP DATABASE extratest;"), "drop extratest DB"; };


