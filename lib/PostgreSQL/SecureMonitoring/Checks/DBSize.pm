package PostgreSQL::SecureMonitoring::Checks::DBSize;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::DBSize -- statistics about database sizes

=head1 SYNOPSIS

=head1 DESCRIPTION

This check returns a list of databases with their sizes


=head2 SQL/Result

The SQL generates a result like this:

    database    | size  
 ---------------+-------
  _posemo_tests |     7 
  postgres      |     7 
  $TOTAL        |    14 
 (3 rows)


=head3 Filter by database name

Results may be filtered with parameter C<skip_db_re>, which is a regular expression filtering the databases. 
Default Filter is C<^template[01]$>, which excludes <template0> and <template1> databases.



=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

has skip_db_re => ( is => "ro", isa => "Str", );



check_has
   name                 => "DB Size",
   description          => 'Get database sizes.',
   has_multiline_result => 1,
   result_unit          => "MB",
   result_type          => "integer",
   parameters           => [ [ skip_db_re => 'TEXT', '^template[01]$' ], ],

   # complex return type
   return_type => q{
      database                        VARCHAR(64), 
      size                            INTEGER
      },

   code => q{
      WITH sizes AS 
         (
         SELECT datname::VARCHAR(64) AS database, (pg_database_size(datname)/1024/1024)::INTEGER AS size
           FROM pg_database 
          WHERE ( CASE WHEN length(skip_db_re) > 0 THEN datname !~ skip_db_re ELSE true END )
       ORDER BY database
         )
       SELECT database, size               FROM sizes
       UNION ALL
       SELECT '$TOTAL', sum(size)::INTEGER FROM sizes;
      };


1;





