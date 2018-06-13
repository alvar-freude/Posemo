#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;
use Test::Deep;
use Test::Differences;

use File::Temp qw(tempdir);
use JSON;
use IO::All;


my $dir = tempdir( CLEANUP => 1 );
$SIG{INT} = $SIG{TERM} = sub { undef $dir; };      # remove temp dir on Ctrl-C or kill


use_ok( "PostgreSQL::SecureMonitoring::Run", output => "JSON" );


ok !-f "$dir/t-701-simple.json", "result file does NOT exist";

my $posemo;



lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/simple-connerror.conf",
                                                     outfile    => "$dir/t-701-simple-connerror.json", );
}, "Object for simple with connectionerror";

lives_ok
   sub { $posemo->run; },
   "Run simple with error";

ok -f "$dir/t-701-simple-connerror.json", "result file exists";

my $json   = io("$dir/t-701-simple-connerror.json")->all;
my $result = decode_json($json);

cmp_ok $result->{error_count}, '>', 0, "There is at least one error";
is $result->{global_id}, "Simple test with error", "Global ID is 'Simple test with error'";


#
# Start non-failing run
#

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                     configfile => "$Bin/conf/simple.conf",
                                                     outfile    => "$dir/t-701-simple.json",
                                                     pretty     => 1,
                                                   );
}, "Object for simple";

lives_ok
   sub { $posemo->run; },
   "Run simple";

ok -f "$dir/t-701-simple.json", "result file exists";

$json = io("$dir/t-701-simple.json")->all;

$result = decode_json($json);

#use Data::Dumper;
#diag Dumper($result);
# diag $dir;

is $result->{error_count}, 0, "No error";
is $result->{global_id}, "Simple test", "Global ID is 'Simple test'";

diag "TODO: analyse result ...";

# sleep 60;



done_testing;
