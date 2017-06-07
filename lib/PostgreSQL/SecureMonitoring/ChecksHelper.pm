package PostgreSQL::SecureMonitoring::ChecksHelper;

=head1 NAME

 PostgreSQL::SecureMonitoring::ChecksHelper -- export some sugar functions for easyer cheks

=head1 SYNOPSIS

In the check class:

 package PostgreSQL::SecureMonitoring::Checks::MyCheck;  # by Default, the name of the check is build from this package name
 
 use PostgreSQL::SecureMonitoring::ChecksHelper;       # This is a Moose class ...
 extends "PostgreSQL::SecureMonitoring::Checks";       # ... which extends our base check class
 
 
 sub _build_sql { return "SELECT 1;"; }                # this sub simply returns the SQL for the check
 
 1;                                                    # every Perl module must return (end with) a true value


=head1 DESCRIPTION




=cut

use Moose;
use Moose::Exporter;

use namespace::autoclean;

use English qw( -no_match_vars );
use Carp qw(croak);

#
# generate all subs;
# TODO: write pod
#

### no critic (BuiltinFunctions::ProhibitStringyEval)
#
#my @subs = qw(enabled return_type result_unit language volatility has_multiline_result has_writes parameters
#   warning_level critical_level min_value max_value);
#
#
#foreach my $sub (@subs)
#   {
#   eval qq{
#
#      sub set_$sub
#         {
#         my ( \$meta, \$value ) = \@ARG;
#         \$meta->add_attribute( "+$sub", default => \$value, );
#         return;
#         }
#      return 1;
#      }
#      or die "Error generating functionfor $sub: $EVAL_ERROR\n";
#
#   }
#

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

      $meta->find_attribute_by_name($attr) or croak "Attribute $attr not found!";

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
Moose::Exporter->setup_import_methods( with_meta => ["check_has"],
                                       also      => 'Moose', );


__PACKAGE__->meta->make_immutable;

1;
