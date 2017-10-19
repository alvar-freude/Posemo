#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;
use Test::Deep;

use_ok("PostgreSQL::SecureMonitoring::Run");

use Carp qw(verbose);

my $app;

lives_ok { $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/test-example.conf" ); } "New run object created";

my @host_groups = $app->all_host_groups;

cmp_deeply( \@host_groups, [qw(Elephant Mammut ApplicationTests)], "Hostgroups found" );


use Data::Dumper;
diag Dumper $app->conf;



done_testing();