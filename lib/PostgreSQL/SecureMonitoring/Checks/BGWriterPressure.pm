package PostgreSQL::SecureMonitoring::Checks::BGWriterPressure;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::BGWriterPressure -- counts high pressure situations in the background writer

=head1 SYNOPSIS

This check has no extra config options beside the defaults.


=head1 DESCRIPTION

This check returns the number of times the background writer stopped a cleaning scan because it had written too many buffers and the number of times a backend had to execute its own fsync call (normally the background writer handles those even when the backend does its own write)
=head2 SQL/Result

The SQL generates a result like this:

 maxwritten_clean | buffers_backend_fsync 
------------------+-----------------------
                0 |                     0

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

#<<<

check_has
   name              => "BG Writer Pressure",
   description       => "High pressure situations in the background writer",
   result_type       => "bigint",
   result_is_counter => 1,
   graph_type        => "area",
   graph_mirrored    => 1,

   # complex return type
   return_type => q{
      maxwritten_clean          bigint,
      buffers_backend_fsync     bigint
      },

   code =>
   "SELECT maxwritten_clean, buffers_backend_fsync FROM pg_stat_bgwriter;";

#>>>

1;
