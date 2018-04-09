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

my $json = io("$dir/t-701-simple.json")->all;

my $result = decode_json($json);

#use Data::Dumper;
#diag Dumper($result);
# diag $dir;

diag "TODO: analyse result ...";

# sleep 60;



done_testing;
