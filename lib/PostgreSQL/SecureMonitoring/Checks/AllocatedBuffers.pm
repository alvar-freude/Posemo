package PostgreSQL::SecureMonitoring::Checks::AllocatedBuffers;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::AllocatedBuffers -- statistics about callocated buffers in the cluster

=head1 SYNOPSIS

This check has no extra config options beside the defaults.


=head1 DESCRIPTION

This check returns the total number of allocated buffers in the cluster.


=head2 SQL/Result

The result is a single bigint value.


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   description       => "Number of allocated buffers",
   return_type       => "bigint",
   result_unit       => "buffers",
   result_is_counter => 1,

   code => q{
      SELECT buffers_alloc FROM pg_stat_bgwriter;
      };


1;


