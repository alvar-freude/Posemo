package PostgreSQL::SecureMonitoring::Checks::Activity;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Activity -- statistics about backend activity (active, idle, ...)

=head1 SYNOPSIS

=head1 DESCRIPTION

This check returns a matrix list of all active sessions on all databases


=head2 SQL/Result

The SQL generates a result like this:

    database    | total | active | idle | idle in transaction | idle in transaction (aborted) | fastpath function call | disabled 
 ---------------+-------+--------+------+---------------------+-------------------------------+------------------------+----------
  _posemo_tests |     1 |      1 |    0 |                   0 |                             0 |                      0 |        0
  postgres      |     0 |      0 |    0 |                   0 |                             0 |                      0 |        0
  template0     |     0 |      0 |    0 |                   0 |                             0 |                      0 |        0
  template1     |     0 |      0 |    0 |                   0 |                             0 |                      0 |        0
  $TOTAL        |     1 |      1 |    0 |                   0 |                             0 |                      0 |        0
 (5 rows)


For each existing database all connections are counted grouped by type, and a summary of all databases is given too.

For future addition:
Filter databases to exclude template DBs etc. via parameter


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   has_multiline_result => 1,

   # complex return type
   return_type => q{
      database                        VARCHAR(64), 
      total                           INTEGER, 
      active                          INTEGER, 
      idle                            INTEGER, 
      "idle in transaction"           INTEGER, 
      "idle in transaction (aborted)" INTEGER, 
      "fastpath function call"        INTEGER, 
      disabled                        INTEGER },

   code => q{
      WITH states AS 
         (
            SELECT db.datname::VARCHAR(64)                                                         AS database, 
                   COUNT(CASE WHEN state IS NOT NULL                       THEN true END)::INTEGER AS total, 
                   COUNT(CASE WHEN state = 'active'                        THEN true END)::INTEGER AS active,
                   COUNT(CASE WHEN state = 'idle'                          THEN true END)::INTEGER AS idle,
                   COUNT(CASE WHEN state = 'idle in transaction'           THEN true END)::INTEGER AS "idle in transaction",
                   COUNT(CASE WHEN state = 'idle in transaction (aborted)' THEN true END)::INTEGER AS "idle in transaction (aborted)",
                   COUNT(CASE WHEN state = 'fastpath function call'        THEN true END)::INTEGER AS "fastpath function call",
                   COUNT(CASE WHEN state = 'disabled'                      THEN true END)::INTEGER AS disabled
              FROM pg_stat_activity AS stat
        RIGHT JOIN pg_database AS db ON stat.datname = db.datname 
          GROUP BY database
          ORDER BY database
         )
       SELECT database, total, 
                        active, 
                        idle, 
                        "idle in transaction", 
                        "idle in transaction (aborted)", 
                        "fastpath function call", 
                        disabled 
         FROM states
       UNION ALL
       SELECT '$TOTAL', sum(total)::INTEGER, 
                        sum(active)::INTEGER, 
                        sum(idle)::INTEGER, 
                        sum("idle in transaction")::INTEGER, 
                        sum("idle in transaction (aborted)")::INTEGER, 
                        sum("fastpath function call")::INTEGER, 
                        sum(disabled)::INTEGER 
         FROM states;
      };


1;
