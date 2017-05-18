package PostgreSQL::SecureMonitoring::Checks::BackupAge;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::BackupAge -- time in seconds, how long a backup label is set

=head1 SYNOPSIS

...

=head1 DESCRIPTION

This check returns the age of a running backup in seconds or NULL if no backup is running.


=cut

use Moose;

extends "PostgreSQL::SecureMonitoring::Checks";

has '+return_type' => ( default => 'integer' );
has '+result_unit' => ( default => 'seconds' );

sub _build_sql
   {
   return "SELECT CASE WHEN pg_is_in_backup()
                       THEN CAST(extract(EPOCH FROM statement_timestamp() - pg_backup_start_time()) AS integer)
                       ELSE NULL
                  END AS backup_age;"
   }

1;
