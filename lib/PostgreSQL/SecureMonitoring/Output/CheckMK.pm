package PostgreSQL::SecureMonitoring::Output::CheckMK;

=head1 NAME 

  PostgreSQL::SecureMonitoring::Output::CheckMK -- check_mk-Output module for posemo
  
=head1 SYNOPSIS

   use PostgreSQL::SecureMonitoring::Run output => "JSON";
   
   my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options();
   $posemo->run;


=head1 DESCRIPTION

This Module generates output for the Check MK monitoring system in PiggybackHosts format. 
All hosts results are in one results file (or output).


=head2 output 

The output is a text with the following elements:


At start:

   <<<posemo>>>
     $METADATA

$METADATA is basic metadata (everything in the first level except the C<result> key in the internal 
data structure or default JSON output) as JSON.


per Host one block with the following content:

  <<<<hostname>>>>
  <<<posemo>>>
     $JSON
  <<<<>>>

$JSON is everything per host (from the internal data structure or default JSON output) as JSON.


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

Implements the output mechanism, here check_mk PiggybackHosts format, 
which is encapsulated JSON.

TODO: Add metrics output.

=cut


sub generate_output
   {
   my $self            = shift;
   my $complete_result = shift;

   my $json = JSON->new->pretty( $self->pretty );

   #
   # basic metadata
   #

   my %metadata;

   foreach my $key ( keys %$complete_result )
      {
      # ignore results
      next if $key eq "result";

      # next if ref $complete_result->{$key};

      $metadata{$key} = $complete_result->{$key};
      }

   $self->add_output( "<<<posemo_base>>>\n" . $json->encode( \%metadata ) . "\n" );


   #
   # Host Data
   #

   foreach my $host_result ( @{ $complete_result->{result} } )
      {
      #<<< no pertidy formatting
      $self->add_output( "<<<<$host_result->{name}>>>>\n" 
              .  "<<<posemo>>>\n" 
              .  $json->encode( $host_result ) . "\n" );
      #>>>
      }

   $self->add_output("<<<<>>>>\n");

   return;
   } ## end sub generate_output



1;
