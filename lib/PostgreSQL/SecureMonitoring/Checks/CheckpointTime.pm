package PostgreSQL::SecureMonitoring::Checks::CheckpointTime;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::CheckpointTime -- statistics about checkpoint write/sync duration

=head1 SYNOPSIS

This check has no extra config options beside the defaults.


=head1 DESCRIPTION

This check returns the checkpoint write and sync times for the complete cluster.


=head2 SQL/Result

The SQL generates a result like this:

  write_time | sync_time 
 ------------+------------
  2264947613 |  2152766


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   description       => "Checkpoint write and sync duration",
   result_type       => "double precision",
   result_unit       => "ms",
   result_is_counter => 1,
   graph_type        => "stacked_area",

   # complex return type
   return_type => q{
      write_time    double precision,
      sync_time     double precision
      },

   code => "SELECT checkpoint_write_time, checkpoint_sync_time FROM pg_stat_bgwriter;";


1;



