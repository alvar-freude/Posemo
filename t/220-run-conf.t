#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use PostgreSQL::SecureMonitoring::Run;

use Carp qw(verbose);

my $app;

lives_ok { $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/../conf/example.conf" ); } "New run object created";

use Data::Dumper;
diag Dumper $app->conf;

pass "Dummy";

done_testing();