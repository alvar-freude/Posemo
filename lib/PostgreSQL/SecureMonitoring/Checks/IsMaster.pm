package PostgreSQL::SecureMonitoring::Checks::IsMaster;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::IsMaster -- checks if machine is master

=head1 SYNOPSIS

In config:

  # fail, when host is no master
  master_required = 1
  
  # or fail, when host is no slave 
  slave_required  = 1

=head1 DESCRIPTION

Returns true if the host is master, else false.

When C<master_required> or C<slave_required> option is set, 
then check fails with critical, when requierement is not met.

By default there is no requirement, so this test fails only 
when host is unreachable.

This check is also an example for overriding the critical/warning 
check method.

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";


has master_required => ( is => "ro", isa => "Bool", );
has slave_required  => ( is => "ro", isa => "Bool", );

check_has
   description => 'Checks if server is master or slave.',
   code        => "SELECT not pg_is_in_recovery() AS is_master;";


=head2 test_critical_warning

Override C<test_critical_warning> with our own check method,
according to C<master_required> and C<slave_required>.

=cut

sub test_critical_warning
   {
   my $self   = shift;
   my $result = shift;

   if ( $self->master_required and not $result )
      {
      $result->{message}  = "Failed ${ \$self->name } for host ${ \$self->host_desc }: not a master.";
      $result->{critical} = 1;
      return;
      }

   if ( $self->slave_required and $result )
      {
      $result->{message}  = "Failed ${ \$self->name } for host ${ \$self->host_desc }: not a slave.";
      $result->{critical} = 1;
      return;
      }

   return;
   } ## end sub test_critical_warning

1;


