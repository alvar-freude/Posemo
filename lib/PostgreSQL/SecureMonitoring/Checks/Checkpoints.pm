package PostgreSQL::SecureMonitoring::Checks::Checkpoints;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Checkpoints -- statistics about BGWriter Checkpoints

=head1 SYNOPSIS

This check has no extra config options beside the defaults.


=head1 DESCRIPTION

This check returns scheduled and requested checkpoints


=head2 SQL/Result

The SQL generates a result like this:

 checkpoints_timed | checkpoints_req 
-------------------+-----------------
             24686 |              83

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

#<<<
check_has
	description       => "Checkpoints scheduled and requested",
	result_type       => "integer",
	result_is_counter => 1,
	graph_type        => "stacked_area",
   graph_colors      => [qw(green purple)],

	# complex return type
	return_type => q{
      checkpoints_timed    bigint,
      checkpoints_req      bigint
      },

	code => "SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;";

#>>>

1;
