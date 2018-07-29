#!/usr/bin/env perl

# TODO: Add Documentation.

use strict;
use warnings;

use 5.010;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use English qw( -no_match_vars );

# init logging before App::Daemon!
use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf( "posemo-logging.properties", "Posemo" ) );

use App::Daemon qw( daemonize );


my $output_module;


my %app_daemon_params;
my @app_daemon_argv;
my $app_daemon_command;
my @posemo_argv;

# set output module and App::Daemon options at beginning!
# rewrite "help" command to "--help" option
BEGIN
{

   foreach my $opt (qw(-X -l -u -g -l4p -p -v))
      {
      my $value = App::Daemon::find_option( $opt, 1 );
      $app_daemon_params{$opt} = $value if defined $value;
      }

   my %allowed_commands = map { $ARG => 1 } qw(start stop status);
   $app_daemon_command = $allowed_commands{ lc( $ARGV[0] // "" ) } ? lc(shift) : "start";

   @posemo_argv     = @ARGV;
   @app_daemon_argv = %app_daemon_params;
   unshift @app_daemon_argv, $app_daemon_command;

   #
   # Posemo start
   #
   if ( @ARGV && $ARGV[0] !~ m{^-} )
      {
      $output_module = shift;
      }
   else
      {
      $output_module = "JSON";
      if ( lc( $ARGV[0] // "" ) eq "help" )
         {
         $ARGV[0] = "--help";                      ## no critic (Variables::RequireLocalizedPunctuationVars)
         }
      }

} ## end BEGIN

use PostgreSQL::SecureMonitoring::Run output => $output_module;

# create test posemo object before daemonizing
@ARGV = @posemo_argv;                              ## no critic (Variables::RequireLocalizedPunctuationVars)

if ( $app_daemon_command eq "start" )
   {
   TRACE "Testing if Posemo parameters are OK (@posemo_argv)";
   my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options( _is_daemon => 1, );
   TRACE "Looks OK";
   INFO "Starting Posemo $PostgreSQL::SecureMonitoring::VERSION as daemon.";
   }
else
   {
   INFO ucfirst($app_daemon_command) . " Posemo $PostgreSQL::SecureMonitoring::VERSION:";
   }

@ARGV = @app_daemon_argv;                          ## no critic (Variables::RequireLocalizedPunctuationVars)

daemonize();
INFO "Posemo now running as daemon.";


@ARGV = @posemo_argv;                              ## no critic (Variables::RequireLocalizedPunctuationVars)

while (1)
   {
   eval {
      my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options( _is_daemon => 1, quiet => 1, );
      $posemo->run;
      sleep( $posemo->sleep_time ) or ERROR "Error with Sleep: $OS_ERROR";
      return 1;
   } or LOGEXIT "Error while executing Posemo: $EVAL_ERROR";
   }

