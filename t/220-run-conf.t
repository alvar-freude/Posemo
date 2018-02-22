#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;
use Test::Deep;

use Test::Differences;

use_ok("PostgreSQL::SecureMonitoring::Run");

# use Carp qw(verbose);

throws_ok sub { my $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/does-not-exists.conf" ); },
   qr(No config loaded, tried with .*conf/does-not-exists.conf), "not existing config file";

throws_ok sub { my $app = PostgreSQL::SecureMonitoring::Run->new( log_config => "$Bin/conf/does-not-exists.conf" ); },
   qr(Given log-config .*conf/does-not-exists.conf does not exist), "given log_config, but does not exist";

throws_ok sub { my $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/test-nonexistent-logging.conf" ); },
   qr(Given log-config /tmp/does/not/exist.conf.never does not exist), "log_config from file, but does not exist";


use Config::FindFile qw(search_conf);
my $default_log_config = search_conf("posemo-logging.properties");

lives_ok sub {
   my $app
      = PostgreSQL::SecureMonitoring::Run->new( log_config => $default_log_config, configfile => "$Bin/conf/test-example.conf" );
}, "New run object with explicit default log conf";


lives_ok sub {
   my $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/test-example.conf",
                                                     log_config => "$Bin/conf/posemo-test-logging.properties", );
}, "App OK with Other logging properties";



my $app;

lives_ok sub { $app = PostgreSQL::SecureMonitoring::Run->new( configfile => "$Bin/conf/test-example.conf" ); },
   "New run object created";

my @host_groups = $app->all_host_groups;

cmp_deeply( \@host_groups, [qw(Elephant Mammut SingleWithName MultiWithName ApplicationTests)], "Hostgroups found" );


#use Data::Dumper;
#diag Dumper $app->conf;


#diag Dumper $app->all_hosts;

my %outer_defaults = (
                       user     => "monitoring",
                       passwd   => "default-blah",
                       schema   => "public",
                       database => "monitoring",
                       port     => "54321",
                     );


my %outer_check_params = (
                           Alive     => { enabled => 0 },
                           Writeable => { timeout => 5000, },
                         );

my %elephant_defaults = ( %outer_defaults, _hostgroup => "Elephant" );

my %elephant_check_params = ( %outer_check_params, Writeable => { enabled => 1, timeout => 100, } );

my %app_defaults = ( %outer_defaults, _hostgroup => "ApplicationTests", schema => "posemo_monitoring", );

my $expected_hosts = [
   {
      %outer_defaults,
      _hostgroup    => "_GLOBAL",
      host          => "database.internal.project.tld",
      _check_params => { %outer_check_params, },
   },

   (
      map {
         {
            %elephant_defaults,
               host          => $_,
               _check_params => { %elephant_check_params, },
         }
         } qw(loc1_db1 loc1_db2 loc2_db1 loc2_db2),
   ),
   {
      %outer_defaults,
      _hostgroup    => "Mammut",
      host          => "loc1_db1",
      port          => 5433,
      _check_params => { %outer_check_params, Trunk => { timeout => 123, }, },
   },

   {
      %outer_defaults,
      _hostgroup    => "Mammut",
      host          => "loc1_db2",
      port          => 5434,
      _check_params => { %outer_check_params, Trunk => { timeout => 456, }, },
   },

   {
      %outer_defaults,
      _hostgroup    => "SingleWithName",
      host          => "123.45.67.89",
      _name         => "my_db_host_name",
      _check_params => { %outer_check_params, Writeable => { enabled => 1, timeout => 999, }, },
   }, 

   {
      %outer_defaults,
      _hostgroup    => "MultiWithName",
      host          => "1.1.1.1",
      _name         => "master_server",
      _check_params => { %outer_check_params, },
   },
   {
      %outer_defaults,
      _hostgroup    => "MultiWithName",
      host          => "2.2.2.2",
      _name         => "slave_server",
      _check_params => { %outer_check_params, },
   },

   {
      %app_defaults,
      host          => "db_lion",
      enabled       => 0,
      _check_params => { %outer_check_params, ApplicationLion => { enabled => 1, } },
   },

   {
      %app_defaults,
      host          => "db_tiger",
      enabled       => 0,
      _check_params => { %outer_check_params, ApplicationTiger => { enabled => 1, critical_level => 1000, } },
   },

   {
      %app_defaults,
      host          => "db_snowtiger",
      enabled       => 0,
      _check_params => { %outer_check_params, ApplicationTiger => { enabled => 1, critical_level => 1000, } },
   },


];

my $all_hosts = $app->all_hosts;

eq_or_diff $all_hosts, $expected_hosts, "All host configs in test config";


done_testing();

