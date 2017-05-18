#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use English qw( -no_match_vars );

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
   if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
   if $@;
   
plan tests => scalar all_modules();

# Don't enforce POD for the default methods in Checks
pod_coverage_ok( 
   $ARG, m{::Checks::} ? 
      { trustme => [qr/^(sql|sql_function|sql_function_name|return_type|language|name)$/] } 
    : {} )
   foreach all_modules();



