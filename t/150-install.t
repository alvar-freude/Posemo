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

my $install;

lives_ok sub {
   $install = PostgreSQL::SecureMonitoring::Install->new(
                                                          database         => "_posemo_tests",
                                                          user             => "_posemo_tests",
                                                          superuser        => "_posemo_superuser",
                                                          port             => 15432,
                                                          create_superuser => 1,
                                                        );
   },
   "survive installer object creation";


BAIL_OUT("FATAL: No install object, leaving") unless $install;

ok( $install, "have monitoring installer object" );

lives_ok sub {
   $install->install;
}, "Installation complete";


done_testing();

