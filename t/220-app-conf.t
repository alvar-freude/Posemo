#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use PostgreSQL::SecureMonitoring::App;



my $app = PostgreSQL::SecureMonitoring::App->new( configfile => "$Bin/../conf/example.conf" );


my $conf = $app->read_config;

ok($conf, "Conf geladen");

use Data::Dumper;
diag Dumper $conf;


done_testing();