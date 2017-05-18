#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::PostgreSQL::Starter;

use_ok("PostgreSQL::SecureMonitoring");

my $tps_conf = pg_read_conf_ok("test");

my ( $app, $check, $result );
lives_ok(
   sub {
      $app = PostgreSQL::SecureMonitoring->new(
                                                database => "_posemo_tests",
                                                user     => "_posemo_tests",
                                                port     => $tps_conf->{port},
                                              );
   },
   "Posemo App Object"
        );
lives_ok( sub { $check = $app->new_check("Alive") }, "Check Object" );

lives_ok( sub { $result = $check->run_check }, "Run Check" );

use Data::Dumper;

diag Dumper $result;


done_testing();
