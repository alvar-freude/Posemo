package PostgreSQL::SecureMonitoring::Checks::Writeable;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Writeable -- writeable check with timeout

=head1 SYNOPSIS

...

=head1 DESCRIPTION

This check checks, if the database is writeable and commits before timeout.

The purpose is to check if a group of master and syncronous slaves are 
ready to accept write queries in time. When at least one streaming replication 
slave is configured as syncronous slave, COMMIT returns after at least one slave 
got the data. When all slaves are gone (or too much behind), then this check fails.


=head2 extras

statement_timeout

=> set statement_timeout to 1000;
SET
=> select pg_sleep(2);
ERROR:  canceling statement due to statement timeout



--


  CREATE USER monitoring PASSWORD 'mon1t0r-r!ng';
  CREATE DATABASE monitoring OWNER monitoring;
  

  BEGIN;
    CREATE TABLE write_test (message text, date_inserted TIMESTAMP WITH TIME ZONE DEFAULT now());
    ALTER TABLE write_test OWNER TO monitoring;
  COMMIT;



my $delete_sql = "DELETE FROM write_test WHERE age(date_inserted, now()) < '-1 day';";
my $check_sql  = "INSERT INTO write_test VALUES ('$check_message') RETURNING date_inserted;";



=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

use Time::HiRes qw(time);

use Sys::Hostname;
use English qw( -no_match_vars );


check_has
   return_type    => "bool",
   result_unit    => "seconds",
   volatility     => "VOLATILE",
   has_writes     => 1,
   warning_level  => 3,
   critical_level => 5,
   parameters     => [ [ msg => 'TEXT' ], ],
   ;


# Attention: attribute message/timeout with it's builder MUST be declared lazy,
# because it uses other attributes!

has timeout => ( is => "ro", isa => "Int", builder => "_build_timeout", lazy => 1, );
has msg     => ( is => "ro", isa => "Str", builder => "_build_message", lazy => 1, );



# need a real build method for code and install_sql, because access to $self
sub _build_code
   {
   my $self = shift;
   return qq{
         DELETE FROM ${ \$self->schema }.writeable WHERE age(date_inserted, now()) < '-1 day';
         INSERT INTO ${ \$self->schema }.writeable VALUES (msg) RETURNING true;
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
   return "Written by $myhost to $dbhost via " . __PACKAGE__;
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
   eval {
      $result = $self->$orig();
      return 1;
   } or $error = $EVAL_ERROR;

   $timing = time - $start;

   $self->dbh->do("SET statement_timeout TO DEFAULT;");

   # On error, we should throw it again, AFTER setting statement_timeout to default.
   die "$error\n" if $error;

   # Change the result: not true as in SQL, but the timing
   $result->{result} = $timing;
   return $result;
};



1;



