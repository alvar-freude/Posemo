package PostgreSQL::SecureMonitoring::Checks::Transactions;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Transactions -- statistics about transactions

=head1 SYNOPSIS

=head1 DESCRIPTION

This check returns a list of databases with (absolute) number of transactions


=head2 SQL/Result

The SQL generates a result like this:

    database    | xact_commit | xact_rollback 
 ---------------+-------------+---------------
  $TOTAL        |          48 |             3
  _posemo_tests |          31 |             3
  postgres      |          17 |             0


=head3 Filter by database name

Results may be filtered with parameter C<skip_db_re>, which is a regular expression filtering the databases. 
Default Filter is C<^template[01]$>, which excludes <template0> and <template1> databases.



=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

has skip_db_re => ( is => "ro", isa => "Str", );



check_has
   description          => 'Get transaction counter.',
   has_multiline_result => 1,
   result_type          => "bigint",
   parameters           => [ [ skip_db_re => 'TEXT', '^template[01]$' ], ],

   # complex return type
   return_type => q{
      database          VARCHAR(64), 
      xact_commit       BIGINT,
      xact_rollback     BIGINT
      },

   code => q{
      WITH xacts AS 
         (
         SELECT datname::VARCHAR(64) AS database, 
                xact_commit,
                xact_rollback
           FROM pg_stat_database 
          WHERE ( CASE WHEN length(skip_db_re) > 0 THEN datname !~ skip_db_re ELSE true END )
       ORDER BY database
         )
       SELECT '$TOTAL', sum(xact_commit)::BIGINT, sum(xact_rollback)::BIGINT FROM xacts
       UNION ALL
       SELECT database, xact_commit, xact_rollback FROM xacts;
      };


1;



