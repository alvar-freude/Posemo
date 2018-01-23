#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use PostgreSQL::SecureMonitoring::Run output => "JSON";

my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options();
$posemo->run;


