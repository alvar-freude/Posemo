package PostgreSQL::SecureMonitoring;

use Moose;
use 5.010;


=head1 NAME

 PostgreSQL::SecureMonitoring - Base Class for PostgreSQL Secure Monitoring Environment

 $Id: SecureMonitoring.pm 675 2017-05-17 15:10:44Z alvar $

=head1 VERSION

Version 0.2.x, $Revision: 675 $

=cut

#<<<
my $BASE_VERSION = "0.1"; use version; our $VERSION = qv( sprintf "$BASE_VERSION.%d", q$Revision: 675 $ =~ /(\d+)/xg );
#>>>


=head1 SYNOPSIS

=encoding utf8


=head1 DESCRIPTION

...

Posemo base class.





... Wie kann ein Result aussehen?


  Checks liefern zum beispiel:
  
    database_name  result_value


Status: OK, warning, critical





Ein Ausgabe-Modul kann auf alle Methoden / Attribute  aus check zugreifen:


  




## NEIN, kein Result-Hash!
  result-hash
  
     {
     name        
     description  => "Check Description",
     class        => 
     state        => "OK", # String: OK, warning, critical
     
     }







=head2 Default Values

Default values for user, database and schema are 




=head2 Config


Paremeter for checks with options:


Writeable

   Timeout = 






Config with Config::General.

See App.pm




=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);

use Log::Log4perl::EasyCatch;


use Moose;

#<<< no perltidy

has configfile  => ( is => "ro", isa => "Str", default   => "$Bin/../conf/posemo.conf", documentation => "Configuration file" );
has log_config  => ( is => "ro", isa => "Str", default   => $DEFAULT_LOG_CONFIG,        documentation => "Alternative logging config" );
has user        => ( is => "ro", isa => "Str", default   => "monitoring",               documentation => "User, running the tests" );
has passwd      => ( is => "ro", isa => "Str",                                          documentation => "Password for monitoring user" );
has schema      => ( is => "ro", isa => "Str", default   => "public",                   documentation => "SQL schema name" );
has database    => ( is => "ro", isa => "Str", default   => "monitoring",               documentation => "Name of monitoring DB", );
has host        => ( is => "ro", isa => "Str", predicate => "has_host",                 documentation => "Hostname/IP to monitor", );
has port        => ( is => "ro", isa => "Int", predicate => "has_port",                 documentation => "Port number for server to monitor", );
has name        => ( is => "ro", isa => "Str", builder  => "_build_name", lazy => 1,    documentation => "Name of the host, for Report (Default: Host)", );

#>>>

with "MooseX::DBI";



=head1 METHODS



=head2 BUILD

Called from Moose at build-time.

Here: initialises the Logger.

=cut

sub BUILD
   {
   my $self = shift;

   # Re-Init loggig, if there is an alternative log config
   if ( $self->log_config ne $DEFAULT_LOG_CONFIG )
      {
      Log::Log4perl->init( $self->log_config );
      DEBUG "Logging initialised with non-default config " . $self->log_config;
      }
   else
      {
      DEBUG "Logging still initialised with default config: $DEFAULT_LOG_CONFIG.";
      }

   return;
   }

sub _build_name
   {
   my $self = shift;
   return $self->host;
   }


=head2 new_check($check_name)

creates and returns a new check object

First loads the check module and then instantiates the check

=cut

sub new_check
   {
   my $self       = shift;
   my $check_name = shift;

   TRACE "Load PostgreSQL::SecureMonitoring::Checks::$check_name";
   eval "require PostgreSQL::SecureMonitoring::Checks::$check_name;"    ## no critic (BuiltinFunctions::ProhibitStringyEval)
      or die "Can't use check $check_name: $EVAL_ERROR\n";

   my $check = "PostgreSQL::SecureMonitoring::Checks::$check_name"->new( app => $self );

   return $check;
   }


#has dbi_dsn     => ( is => "ro", isa => "Str", );
#has dbi_user    => ( is => "ro", isa => "Str", );
#has dbi_passwd  => ( is => "ro", isa => "Str", );
#has dbi_options => ( is => "ro", isa => "HashRef", default => sub { return { RaiseError => 1, AutoCommit => 0 } } );


=head2 dbi_dsn, dbi_user, dbi_passwd, dbi_options

Required by MooseX::DBI.

DSN: Build from database, host and port

Options always fixed: RaiseError on, AutoCommit off

=cut

sub dbi_dsn
   {
   my $self = shift;

   my $host_str = $self->has_host ? ";host=${ \$self->host }" : "";
   my $port_str = $self->has_port ? ";port=${ \$self->port }" : "";

   return "dbi:Pg:dbname=${ \$self->database }$host_str$port_str";
   }

sub dbi_user
   {
   my $self = shift;
   return $self->user;
   }

sub dbi_passwd
   {
   my $self = shift;
   return $self->passwd;
   }

sub dbi_options
   {
   return { RaiseError => 1, AutoCommit => 0 };
   }



=head2 ->host_desc

This method returns a host description as string. When we have a host, 
then this is returned.

When no host is set, then this is talken from PGHOST environment, if available, 
or a message indicating that nohst is given.


Don't use the returnvalue for connecting; use it for messages and debug output!


=cut


sub host_desc
   {
   my $self = shift;

   my $port = $self->has_port ? $self->port : "";

   return $self->host . $port if $self->has_host;
   return "<via PGHOST: $ENV{PGHOST}:$port>" if $ENV{PGHOST};
   return "<no host / localhost:$port>";
   }


=head1 AUTHOR

Alvar C.H. FReude, C<< <"alvar at a-blast.org"> >>

#
#=head1 BUGS
#
#Please report any bugs or feature requests to C<bug-tls-check at rt.cpan.org>, or through
#the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TLS-Check>.  I will be notified, and then you'll
#automatically be notified of progress on your bug as I make changes.
#
#
#
#
#=head1 SUPPORT
#
#You can find documentation for this module with the perldoc command.
#
#    perldoc TLS::Check
#
#
#You can also look for information at:
#
#=over 4
#
#=item * RT: CPAN's request tracker (report bugs here)
#
#L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TLS-Check>
#
#=item * AnnoCPAN: Annotated CPAN documentation
#
#L<http://annocpan.org/dist/TLS-Check>
#
#=item * CPAN Ratings
#
#L<http://cpanratings.perl.org/d/TLS-Check>
#
#=item * Search CPAN
#
#L<http://search.cpan.org/dist/TLS-Check/>
#
#=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alvar C.H. Freude, http://alvar.a-blast.org/


This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

#Any use, modification, and distribution of the Standard or Modified
#Versions is governed by this Artistic License. By using, modifying or
#distributing the Package, you accept this license. Do not use, modify,
#or distribute the Package, if you do not accept this license.
#
#If your Modified Version has been derived from a Modified Version made
#by someone other than you, you are nevertheless required to ensure that
#your Modified Version complies with the requirements of this license.
#
#This license does not grant you the right to use any trademark, service
#mark, tradename, or logo of the Copyright Holder.
#
#This license includes the non-exclusive, worldwide, free-of-charge
#patent license to make, have made, use, offer to sell, sell, import and
#otherwise transfer the Package with respect to any patent claims
#licensable by the Copyright Holder that are necessarily infringed by the
#Package. If you institute patent litigation (including a cross-claim or
#counterclaim) against any party alleging that the Package constitutes
#direct or contributory patent infringement, then this Artistic License
#to you shall terminate on the date that such litigation is filed.
#
#Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
#AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
#THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
#PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
#YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
#CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
#CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
#EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;

