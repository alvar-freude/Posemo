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


=head2 Additional attributes

=over 4

=item * pretty

Flag (boolean), if the output should be formatted pretty or compact (default).


=back

=cut

has pretty => ( is => "ro", isa => "Bool", default => 0, );


=head1 METHODS

=head2 generate_output

Implements the output mechanism, here plain JSON.

=cut


sub generate_output
   {
   my $self            = shift;
   my $complete_result = shift;

   my $json = JSON->new->pretty( $self->pretty );

   return $json->encode($complete_result);
   }

1;

