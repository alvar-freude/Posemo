package PostgreSQL::SecureMonitoring::Output::JSON;

=head1 NAME

 PostgreSQL::SecureMonitoring::Output::JSON - Role for JSON output

=head1 SYNOPSIS

=encoding utf8

 with "PostgreSQL::SecureMonitoring::Output::JSON";
 # [...]
 print $self->output_as_string;

=head1 DESCRIPTION

This role implements the output_as_string method.

Here it simply converts the given result to JSON without any conversion or other changes.

=cut


use Moose::Role;

use JSON;

=head1 METHODS

=head2 output_as_string

Implements the output mechanism, here plain JSON.

=cut


sub output_as_string
   {
   my $self            = shift;
   my $complete_result = shift;

   return encode_json($complete_result);
   }

1;

