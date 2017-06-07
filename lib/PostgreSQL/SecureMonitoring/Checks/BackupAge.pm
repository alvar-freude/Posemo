package PostgreSQL::SecureMonitoring::Checks::BackupAge;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::BackupAge -- time in seconds, how long a backup label is set

=head1 SYNOPSIS

...
In config file: 

  warning_level  = 7200       # 2 hours
  critical_level = 10800      # 3 hours

=head1 DESCRIPTION

This check returns the age of a running backup in seconds or NULL if no backup is running.


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   return_type => 'integer',
   result_unit => 'seconds',
   code        => "SELECT CASE WHEN pg_is_in_backup()
                               THEN CAST(extract(EPOCH FROM statement_timestamp() - pg_backup_start_time()) AS integer)
                               ELSE NULL
                               END 
                          AS backup_age;";



1;
