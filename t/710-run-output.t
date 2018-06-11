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


BEGIN
{
   eval "use Test::Output";
   plan skip_all => "Test::Output required for testing output" if $@;

}

my $dir = tempdir( CLEANUP => 1 );
$SIG{INT} = $SIG{TERM} = sub { undef $dir; };      # remove temp dir on Ctrl-C or kill

my $resultfile = "$dir/t-710-run.json";



ok !-f $resultfile, "result file does NOT exist";

my $posemo;

{
   # for Log::Log4Perl::EasyCatch: ignore, that we are in testing at first init.
   local $ENV{HARNESS_ACTIVE} = 0;
   use_ok("PostgreSQL::SecureMonitoring::Run");
   lives_ok sub {
      $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                        configfile => "$Bin/conf/simple.conf",
                                                        outfile    => $resultfile,
                                                        pretty     => 1,
                                                      );
   }, "Object for simple";

}

my $out = stderr_from sub { $posemo->run; };

like $out, qr{INFO : PostgreSQL Secure Monitoring version .* All Checks Done.}ms, "Output has begin and end text.";
unlike $out, qr{TRACE.*DEBUG}ms, "Output has no verbose output and debug.";

undef $posemo;

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                     configfile => "$Bin/conf/simple.conf",
                                                     outfile    => $resultfile,
                                                     quiet      => 1,
                                                   );
}, "Object for simple qiet";


stderr_is sub { $posemo->run; }, "", "Output empty for quiet.";


undef $posemo;

$out = stderr_from
{
   lives_ok sub {
      $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                        configfile => "$Bin/conf/simple.conf",
                                                        outfile    => $resultfile,
                                                        verbose    => 1,
                                                      );
   }, "Object for simple verbose";
};

like $out, qr{TRACE.*DEBUG}ms, "->new creates verbose output";



stderr_like sub { $posemo->run; }, qr{TRACE.*DEBUG}ms, "Full output for verbose.";


undef $posemo;

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/simple.conf",
                                                     outfile    => $resultfile, );
}, "Object for simple normal again";


$out = stderr_from sub { $posemo->run; };

like $out, qr{INFO : PostgreSQL Secure Monitoring version .* All Checks Done.}ms, "Again: Output has begin and end text.";
unlike $out, qr{TRACE.*DEBUG}ms, "Again: Output has no verbose output and debug.";


undef $posemo;
throws_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                     configfile => "$Bin/conf/simple.conf",
                                                     verbose    => 1,
                                                     quiet      => 1,
                                                   );
}, qr{screen output can not be verbose and quiet at the same time}, "Can't use quiet and verbose at same time";



undef $posemo;

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/simple.conf", );
}, "Object for simple with STDOUT output";


my $stderr = stderr_from
{
   $out = stdout_from
   {
      $posemo->run;
   };

};

like $stderr, qr{INFO : PostgreSQL Secure Monitoring version .* All Checks Done.}ms,
   "With STDOUT-Result: STDERR has begin and end text.";
unlike $stderr, qr{TRACE.*DEBUG}ms, "With STDOUT-Result: STDERR has no verbose output and debug.";


my $result;
lives_ok sub { $result = decode_json($out) }, "lives OK for decode JSON from STDOUT";

is ref $result, "HASH", "Decoded result is a hashref";

is $result->{global_id}, "Simple test", "Found 'simple test' global ID in result";


done_testing;
