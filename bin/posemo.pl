#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

my $output_module;

# set output module at beginning!
BEGIN
{

   if ( @ARGV && $ARGV[0] !~ m{^-} )
      {
      $output_module = shift;
      }
   else
      {
      $output_module = "JSON";
      }
}

use PostgreSQL::SecureMonitoring::Run output => $output_module;

my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options();
$posemo->run;


