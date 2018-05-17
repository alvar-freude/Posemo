package PostgreSQL::SecureMonitoring::Checks::CacheHitRatio;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::CacheHitRatio -- gets the cache hit ratio by database

=head1 SYNOPSIS

  # In config:
  # Here an example, for a big database / low memory situation
  <Check CacheHitRatio>
    warning_level  = 50   # default 80
    critical_level = 20   # default 60
  </Check>
  
  # or, if you have enough memory
  <Check CacheHitRatio>
    warning_level  = 95   # default 80
    critical_level = 90   # default 60
  </Check>


=head1 DESCRIPTION

This check returns the cache hit ratio (buffer cache only!) by database.

It has a warning and critical level, which you may want to change. 
When you have enough RAM, you should usually have a cache hit ratio above 95% 
for most databases. The default values are 80% for warning and 60% for critical. 


=head2 SQL/Result

The SQL generates a result like this:

    database    | cache_hit_ratio 
 ---------------+-----------------
  $TOTAL        |         97.5702
  _posemo_tests |         97.7321
  postgres      |         89.9823


=head3 Filter by database name

Results may be filtered with parameter C<skip_db_re>, which is a regular expression filtering the databases. 
Default Filter is C<^template[01]$>, which excludes <template0> and <template1> databases.



=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

has skip_db_re => ( is => "ro", isa => "Str", );



check_has
   description          => 'Get cache hit ratio',
   has_multiline_result => 1,
   result_unit          => q{%},
   result_type          => "real",
   arguments            => [ [ skip_db_re => 'TEXT', '^template[01]$' ], ],
   min_value            => 0,
   max_value            => 100,
   warning_level        => 80,
   critical_level       => 60,
   lower_is_worse       => 1,

   # complex return type
   return_type => q{
      database                        VARCHAR(64), 
      cache_hit_ratio                 REAL
      },

   code => q{
      WITH ratio AS 
         (
         SELECT datname::VARCHAR(64) AS database, 
                blks_read,
                blks_hit,
                CASE WHEN blks_hit = 0 
                   THEN 0 
                   ELSE 100::float8*blks_hit::float8/(blks_read+blks_hit)
                END AS cache_hit_ratio
           FROM pg_stat_database 
          WHERE ( CASE WHEN length(skip_db_re) > 0 THEN datname !~ skip_db_re ELSE true END )
       ORDER BY database
         )
       SELECT '$TOTAL' AS database,
              CAST( 
                   (
                   CASE WHEN sum(blks_hit) = 0 
                     THEN 0 
                     ELSE 100::float8*sum(blks_hit)::float8/(sum(blks_read)+sum(blks_hit))
                   END 
                   ) AS real)
                  AS cache_hit_ratio
         FROM ratio
       UNION ALL
       SELECT database, cache_hit_ratio::real FROM ratio;
      };


1;



