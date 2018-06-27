package PostgreSQL::SecureMonitoring::Checks::Alive;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Alive -- minimalistic alive check

=head1 SYNOPSIS

In Config:

  # Optionally you may change the behaviour when there is a hard error
  # Default is: critical on error.
  <Check Alive>
    no_critical    = 1
    warn_if_failed = 1
  </Check>

=head1 DESCRIPTION

This was a minimalistic Posemo check, now it has some error handling. 
This check creates a SQL for a simple function, 
which just returns true. So, if the server is alive, then it returns true.

Connection errors and other hard errors are catched, so the check returns 
a fail message if failed (and not a connection error).

In the config you can configure, that a failed connection should not 
result in a critical result and/or create a warning instead. 


=cut

use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

use English qw( -no_match_vars );

has no_critical    => ( is => "ro", isa => "Bool", );
has warn_if_failed => ( is => "ro", isa => "Bool", );

check_has
   description => 'Checks if server is alive.',
   code        => "SELECT true";


=head2 Modify execute

We modify the execute method, wrap the original in eval (try) and 
build manually a result when failed.

=cut

around execute => sub {
   my $orig = shift;
   my $self = shift;

   my $result;
   eval {                                          # catch errors
      $result = $self->$orig();                    # Call original execute method here
      return 1;
      } or do
      {                                            # when failed, then set fail messages and build result.
      $result->{result}   = 0;
      $result->{row_type} = "single";
      $result->{message}  = "Failed Alive check for host ${ \$self->host_desc }; error: $EVAL_ERROR";
      $result->{critical} = 1 unless $self->no_critical;
      $result->{warning}  = 1 if $self->warn_if_failed;
      $result->{columns}  = [qw(alive)];
      };

   return $result;

};


=begin NoRendering

=head2 test_critical_warning

override test_critical_warning with empty sub, because everythhing is done above.

=end NoRendering

=cut 


sub test_critical_warning { return; }


1;
