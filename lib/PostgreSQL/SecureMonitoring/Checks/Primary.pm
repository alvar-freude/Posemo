package PostgreSQL::SecureMonitoring::Checks::Primary;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Primary -- checks if this cluster is a primary (master)

=head1 SYNOPSIS

This check has two options in config:

  <Check Primary>
    # fail, when host is no primary (master)
    is_primary = 1
  
    # or fail, when host is primary (master)
    isnt_primary  = 1
  </Check>

=head1 DESCRIPTION

Returns true if the host is the primary (master), else false.

When C<is_primary> or C<isnt_primary> option is set, 
then the check fails with critical, when requierement is not met.

For developers: This check is also an example for overriding the critical/warning 
check method.

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";


has is_primary   => ( is => "ro", isa => "Bool", );
has isnt_primary => ( is => "ro", isa => "Bool", );

check_has
   description => 'Checks if server is primary (master) not (secondary, slave).',
   code        => "SELECT not pg_is_in_recovery() AS primary;";


=head2 test_critical_warning

Override C<test_critical_warning> with our own check method,
according to C<is_primary> and C<isnt_primary>.

=cut

sub test_critical_warning
   {
   my $self   = shift;
   my $result = shift;

   if ( $self->is_primary and not $result )
      {
      $result->{message}  = "Failed ${ \$self->name } for host ${ \$self->host_desc }: not a primary (master).";
      $result->{critical} = 1;
      return;
      }

   if ( $self->isnt_primary and $result )
      {
      $result->{message}
         = "Failed ${ \$self->name } for host ${ \$self->host_desc }: it is a primary (master), not secondary (slave) as requested.";
      $result->{critical} = 1;
      return;
      }

   return;
   } ## end sub test_critical_warning

1;


