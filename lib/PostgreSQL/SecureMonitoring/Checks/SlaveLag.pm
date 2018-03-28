package PostgreSQL::SecureMonitoring::Checks::SlaveLag;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::SlaveLag -- checks if the machine is a slave and returns the replication lag

=head1 SYNOPSIS

This check has no other config options then the default.

=head1 DESCRIPTION

This check returns the replication lag in seconds (as double precision/floting point value) 
or NULL if this is not a reopication slave (not in recovery).

=cut

use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   description => 'When the server is a slave, then return the replication lag in seconds.',
   return_type => 'double precision',
   result_unit => 'seconds',
   code        => "SELECT CASE WHEN pg_is_in_recovery()
                               THEN extract(EPOCH FROM clock_timestamp() - pg_last_xact_replay_timestamp()) 
                               ELSE NULL
                               END 
                          AS backup_age;";


1;
