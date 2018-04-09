#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

my $output_module = "JSON";

if (@ARGV && $ARGV[0] !~ m{^-})
   {
   $output_module = shift;
   }

use PostgreSQL::SecureMonitoring::Run output => shift // "JSON";

my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options();
$posemo->run;


