package PostgreSQL::SecureMonitoring::Checks::ConnectionLimit;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::ConnectionLimit -- percent if used connections

=head1 SYNOPSIS

  # In config:
  # check, that connections doesn't are not higher then this (in percent of max_connections)
  <Check ConnectionLimit>
    warning_level  = 75   # default 75
    critical_level = 90   # default 90
  </Check>


=head1 DESCRIPTION

This check tests the used connections compared to C<max_connections> 
config setting of the PostgreSQL server.

It has a warning and critical level, which you may want to change. 


=head2 SQL/Result

The SQL generates a result like this:

   connection_limit_reached
 ---------------------------
                     12.345


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   description    => 'Percent of max_connections used',
   result_unit    => q{%},
   return_type    => "real",
   min_value      => 0,
   max_value      => 100,
   warning_level  => 75,
   critical_level => 90,
   code           => q{ SELECT ((sum(numbackends) / current_setting('max_connections')::real)*100)::real 
                            AS connection_limit_reached 
                          FROM pg_stat_database; };


1;
