#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Run always!
#unless ( $ENV{RELEASE_TESTING} || $ENV{TEST_AUTHOR} )
#   {
#   plan( skip_all => "Author tests not required for installation (set TEST_AUTHOR)" );
#   }

# Needs 1.33 because symlink bug, later need newer because more symlink bugs
# It's only a developer check, so doesn't matter if skipped 
my $min_tcm = 1.42;                                
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
