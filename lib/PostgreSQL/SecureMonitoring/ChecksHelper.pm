package PostgreSQL::SecureMonitoring::ChecksHelper;

=head1 NAME

 PostgreSQL::SecureMonitoring::ChecksHelper -- export some sugar functions for easyer cheks

=head1 SYNOPSIS

In the check class:

 package PostgreSQL::SecureMonitoring::Checks::Seconds; # by Default, the name of the check is build from this package name
 
 use PostgreSQL::SecureMonitoring::ChecksHelper;        # This is a Moose class ...
 extends "PostgreSQL::SecureMonitoring::Checks";        # ... which extends our base check class
 
 check_has
   return_type => 'integer',
   result_unit => 'seconds',
   code        => "SELECT date_part('seconds',  now());";
 
 1;                                                    # every Perl module must return (end with) a true value


=head1 DESCRIPTION




=cut

use Moose;
use Moose::Exporter;

use namespace::autoclean;

use English qw( -no_match_vars );
use Carp qw(croak);

#
# TODO: write pod
#


#
# export check_has sub and all from Moose
#

Moose::Exporter->setup_import_methods( with_meta => ["check_has"],
                                       also      => 'Moose', );



=head2 check_has

Set all attributes for the check.

Can called multiple times.

=cut

# map for builder attributes
# and other mappings
my %attr_map = (
                 code        => "_code_attr",
                 result_type => "_result_type_attr",
               );

sub check_has
   {
   my ( $meta, @params ) = @ARG;

   croak "check_has needs key-value pairs as parameters." if @params == 0 or @params % 2 == 1;

   do
      {
      my $attr  = shift @params;
      my $value = shift @params;

      $attr = $attr_map{$attr} if $attr_map{$attr};

      $meta->find_attribute_by_name($attr) or croak "Attribute '$attr' not found!";

      if ( ref $value )
         {
         $meta->add_attribute( "+$attr", default => sub { $value } );
         }
      else
         {
         $meta->add_attribute( "+$attr", default => $value );
         }

      } while @params;

   return;
   } ## end sub check_has


__PACKAGE__->meta->make_immutable;

1;
