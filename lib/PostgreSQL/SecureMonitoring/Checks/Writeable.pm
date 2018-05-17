package PostgreSQL::SecureMonitoring::Checks::Writeable;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Writeable -- writeable check with timeout

=head1 SYNOPSIS

  # Example config, only necessary for overwriting the defaults 
  <Check Writeable>
    timeout          = 6000         # timeout 6000 ms (extra parameter for this check); default: critical_level in ms (*1000)
    retention_period = "8 hours"    # delete old old table entries after 8 hours; ()default: 1 day)
    warning_level    = 2            # warning after 2 seconds (default: 3)
    critical_level   = 4            # critical after 4 seconds (default: 5)
  </Check>
 

=head1 DESCRIPTION

This check checks, if the database is writeable and commits before timeout. 
With every call it writes a row to a table and deletes old entries.

The purpose is to check if a group of master and syncronous slaves are 
ready to accept write queries in time. When at least one streaming replication 
slave is configured as syncronous slave, COMMIT returns after at least one slave 
got the data. When all slaves are gone (or too much behind), then this check fails.

=head2 Parameters

This check has the following additional parameters: 

=over 4

=item * C<timeout>.

This is the amount of milliseconds, after which the check will be canceled. Default is C<critical_level> 
in milliseconds (critical_level*1000).

Timeout should not be shorter then C<critical_level*1000>, because with shorter timeout, 
critical_level can't be reached.


=item * C<retention_period>

A string with an SQL-C<INTERVAL> value. If a row is older then this, it will be deleted.


=item * C<message>

A message, which is written to the table. The default message contains 
info about the connecting and connected host.


=item * C<warning_level>, C<critical_level>

This are standard attributes, this check sets them to 3 and 5 seconds.


=back

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

use Time::HiRes qw(time);

use Sys::Hostname;
use English qw( -no_match_vars );


# Here check_has has NO code; this is defined below.
check_has
   description    => 'Try to write and commit before timeout.',
   return_type    => "bool",                       # the SQL-functions returns true/false
   result_type    => "float",                      # but the check itself returns seconds as float
   result_unit    => "s",
   volatility     => "VOLATILE",                   # Our check modifies the database ...
   has_writes     => 1,                            # ... and needs a commit.
   warning_level  => 3,
   critical_level => 5,
   arguments => [ [ message => 'TEXT' ], [ retention_period => 'INTERVAL', '1 day' ], ],
   ;


# Extra attribute declaration
# attribute message/timeout with it's builder MUST be declared lazy,
# because builder method uses other attributes!
# Retention_period has no default, because the default is encoded in the SQL function definition

has retention_period => ( is => "ro", isa => "Str", predicate => "has_retention_period", );
has timeout          => ( is => "ro", isa => "Int", builder   => "_build_timeout", lazy => 1, );
has message          => ( is => "ro", isa => "Str", builder   => "_build_message", lazy => 1, predicate => "has_message", );


# The code for building the check is given by the following method.
# We need a real build method for code and install_sql, because access to $self.
sub _build_code
   {
   my $self = shift;
   return qq{
         DELETE FROM ${ \$self->schema }.writeable WHERE age(statement_timestamp(), date_inserted) > retention_period;
         INSERT INTO ${ \$self->schema }.writeable VALUES (message) RETURNING true;
   };
   }

sub _build_install_sql
   {
   my $self = shift;

   return qq{
      CREATE TABLE ${ \$self->schema }.writeable (message text, date_inserted TIMESTAMP WITH TIME ZONE DEFAULT now());
      ALTER TABLE ${ \$self->schema }.writeable OWNER TO ${ \$self->superuser };
      REVOKE ALL ON ${ \$self->schema }.writeable FROM PUBLIC;
      GRANT INSERT, DELETE ON ${ \$self->schema }.writeable TO ${ \$self->superuser };
    };
   }


# Default timeout is the critical level (which is in seconds)
sub _build_timeout
   {
   my $self = shift;
   return $self->critical_level * 1000;
   }

# Create a default message from the host names
sub _build_message
   {
   my $self   = shift;
   my $dbhost = $self->host // "<local>";
   my $myhost = hostname;
   return "Written by $myhost to $dbhost via ${ \$self->name }";
   }


=head2 around execute

Because we need some extras to the execution of the function (timing and timeout), 
an around modifier is necessary.

This can't be implemented in plpgsql, because statement_timeout works for 
the complete function, not single statements inside the function.

=cut

around 'execute' => sub {
   my $orig = shift;
   my $self = shift;

   $self->dbh->do("SET statement_timeout TO ${ \$self->timeout };");

   # get timing and catch error
   my ( $error, $timing );
   my $start = time;
   my $result;
   eval {                                          # catch errors
      $result = $self->$orig();                    # Call original execute method here
      return 1;
   } or $error = $EVAL_ERROR;

   $timing = time - $start;

   $self->dbh->do("SET statement_timeout TO DEFAULT;");

   # On error, we should throw it again, AFTER setting statement_timeout to default.
   die "$error\n" if $error;

   # Change the result: not true as from SQL, but the timing
   $result->{result} = $timing;
   return $result;
};



1;

