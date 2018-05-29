package PostgreSQL::SecureMonitoring::Checks::ReadWriteTime;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::ReadWriteTime -- Time spent reading/writing data file blocks  

=head1 SYNOPSIS


   # enable, disabled by default because timing must be enabled
   <Check ReadWriteTime>
      enabled = 1
   </Check>

=head1 DESCRIPTION

This check returns a list of databases with read and write IO times. 
B<Disabled> by default, because it needs config C<track_io_timing> enabled!

See L<PostgreSQL Documentation for track_io_timing|https://www.postgresql.org/docs/current/static/runtime-config-statistics.html#GUC-TRACK-IO-TIMING> 
for enabling timing and about timing overhead.


=head2 SQL/Result

The SQL generates a result like this:

  Example TODO


=head2 TODO

TODO: Tests!


=head3 Filter by database name

Results may be filtered with parameter C<skip_db_re>, which is a regular expression filtering the databases. 
Default Filter is C<^template[01]$>, which excludes <template0> and <template1> databases.



=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

has skip_db_re => ( is => "ro", isa => "Str", );



check_has
   name                 => "Read/Write Time",
   description          => "Time spent reading/writing data file blocks.",
   enabled              => 0,
   result_type          => "double precision",
   result_unit          => "ms",
   result_is_counter    => 1,
   graph_mirrored       => 1,                      # display read/writeobove/below middle line
   graph_type           => "area",
   has_multiline_result => 1,
   arguments            => [ [ skip_db_re => 'TEXT', '^template[01]$' ], ],

   # complex return type
   return_type => q{
      database       VARCHAR(64), 
      read_time      double precision,
      write_time     double precision
      },

   code => q{
      WITH rw AS 
         (
         SELECT datname::VARCHAR(64) AS database, 
                blk_read_time  AS read_time,
                blk_write_time AS write_time
           FROM pg_stat_database 
          WHERE ( CASE WHEN length(skip_db_re) > 0 THEN datname !~ skip_db_re ELSE true END )
       ORDER BY database
         )
       SELECT '$TOTAL', sum(read_time) AS read_time, sum(write_time) AS write_time FROM rw
       UNION ALL
       SELECT database, read_time, write_time FROM rw;
      };


1;



