package PostgreSQL::SecureMonitoring;

use Moose;
use 5.010;


=head1 NAME

 PostgreSQL::SecureMonitoring - Base Class for PostgreSQL Secure Monitoring Environment

=head1 VERSION

Version 0.4.0

=cut

use version; our $VERSION = qv("v0.6.1");


=head1 SYNOPSIS

=encoding utf8


=head1 DESCRIPTION


Posemo base class.

...





=head2 Config

Config with Config::General.

See App.pm




=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);

use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf("posemo-logging.properties") );


use Moose;

#<<< no perltidy

has log_config      => ( is => "ro", isa => "Str", default   => $DEFAULT_LOG_CONFIG,      documentation => "Alternative logging config" );
has user            => ( is => "ro", isa => "Str", default   => "posemo",                 documentation => "User, running the tests" );
has passwd          => ( is => "ro", isa => "Str",                                        documentation => "Password for monitoring user" );
has schema          => ( is => "ro", isa => "Str", default   => "posemo",                 documentation => "SQL schema name" );
has database        => ( is => "ro", isa => "Str", default   => "monitoring",             documentation => "Name of monitoring DB", );
has host            => ( is => "ro", isa => "Str", predicate => "has_host",               documentation => "Hostname/IP to monitor", );
has port            => ( is => "ro", isa => "Int", predicate => "has_port",               documentation => "Port number for server to monitor", );
has name            => ( is => "ro", isa => "Str", builder   => "_build_name", lazy => 1, documentation => "Name of the host, for Report (Default: Host)", );
has _server_version => ( is => "ro", isa => "Int", builder   => "_build_server_version",  reader => "server_version", lazy => 1, documentation => "(internal) Server Version", );

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
   return $self->host // "<no host>";
   }

sub _build_server_version
   {
   my $self = shift;
   my $pg_version;
   eval { ($pg_version) = $self->dbh->selectrow_array("SHOW server_version_num;"); return 1; } or return -1;
   return $pg_version;
   }


=head2 get_all_checks, get_all_checks_ordered

Returns a list of all installed checks. A check is installed, when it is found as module. Therefore it
should be installed in C<@INC> in C<PostgreSQL/SecureMonitoring/Checks>.

Both can be called as instance and class method.

The results are cached, so changes during the runtime are not recognised.

C<get_all_checks_ordered> returns an ordered and filtered list of all checks:
Sort order is by return value of an object method "order" (string order, default check name).
And grep for "enabled_on_this_platform" (default true).

=cut

my @all_checks;
my @all_checks_ordered;

sub get_all_checks
   {
   @all_checks = _uniqstr( map { _file2checkname($ARG); } map { <$ARG/PostgreSQL/SecureMonitoring/Checks/*.pm> } @INC )
      unless @all_checks;
   return @all_checks;
   }

# uniqstr is only available in newer List::Util versions
sub _uniqstr ()                                    ## no critic (Subroutines::RequireArgUnpacking)
   {
   my %seen;
   my @uniq = grep { !$seen{$_}++ } @_;
   return @uniq;
   }


sub get_all_checks_ordered
   {
   my $self = shift;

   my %checks = map {
      _load_module("PostgreSQL::SecureMonitoring::Checks::$ARG");
      $ARG => "PostgreSQL::SecureMonitoring::Checks::$ARG"->new( app => $self );
   } $self->get_all_checks;

   #<<<
   @all_checks_ordered =
        sort { $checks{$a}->order cmp $checks{$b}->order }
        grep { $checks{$ARG}->enabled_on_this_platform }
        keys %checks
      unless @all_checks_ordered;
   #>>>

   return @all_checks_ordered;
   }

sub _file2checkname
   {
   my $file = shift;
   my ($check_name) = $file =~ m{ ([^/]+) [.] pm $ }x;
   return $check_name;
   }


=head2 new_check($check_name)

creates and returns a new check object

First loads the check module and then instantiates the check

=cut

sub new_check
   {
   my $self       = shift;
   my $check_name = shift;
   my $params     = shift;

   my $module = "PostgreSQL::SecureMonitoring::Checks::$check_name";
   _load_module($module);
   my $check = $module->new( app => $self, %$params );

   return $check;
   }

sub _load_module
   {
   my $module = shift;

   TRACE "Load $module";

   eval "use $module; return 1;"                   ## no critic (BuiltinFunctions::ProhibitStringyEval)
      or die "Can't load module $module: $EVAL_ERROR\n";

   return 1;
   }


#has dbi_dsn     => ( is => "ro", isa => "Str", );
#has dbi_user    => ( is => "ro", isa => "Str", );
#has dbi_passwd  => ( is => "ro", isa => "Str", );
#has dbi_options => ( is => "ro", isa => "HashRef", default => sub { return { RaiseError => 1, AutoCommit => 0 } } );


=head2 dbi_dsn, dbi_user, dbi_passwd, dbi_options

Required by MooseX::DBI.

DSN: Build from database, host and port

Options always fixed: RaiseError on, AutoCommit off

When host is "-", then the complete DSN is set to "-" (means STDOUT)

=cut

sub dbi_dsn
   {
   my $self = shift;

   return q{-} if $self->has_host and $self->host eq q{-};

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

   my $port;
   if    ( $self->has_port ) { $port = q{:} . $self->port; }
   elsif ( $ENV{PGPORT} )    { $port = q{:} . $ENV{PGPORT}; }
   else                      { $port = ""; }

   return $self->host . $port if $self->has_host;
   return "<via PGHOST: $ENV{PGHOST}:$port>" if $ENV{PGHOST};
   return "<no host / localhost:$port>";
   }


=head1 AUTHOR

Alvar C.H. FReude, C<< <"alvar at a-blast.org"> >>


=head1 BUGS

Please report any bugs or feature requests in the GitHub Repository:

  http://github.com/alvar-freude/Posemo




=head1 SUPPORT

You can find documentation for this module and all others in this distribution with the perldoc command.

    perldoc PostgreSQL::SecureMonitoring


=begin TODO

#You can also look for information at:
#
#=over 4
#
#=item * RT: CPAN's request tracker (report bugs here)
#
#L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=...>
#
#=item * AnnoCPAN: Annotated CPAN documentation
#
#L<http://annocpan.org/dist/...>
#
#=item * CPAN Ratings
#
#L<http://cpanratings.perl.org/d/...>
#
#=item * Search CPAN
#
#L<http://search.cpan.org/dist/.../>
#
#=back

=end TODO


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 - 2017 Alvar C.H. Freude, http://alvar.a-blast.org/

Posemo is released under the L<PostgreSQL License|https://opensource.org/licenses/postgresql>, a liberal Open Source license, similar to the BSD or MIT licenses.

Copyright (c) 2016, 2017, Alvar C.H. Freude and contributors

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement
is hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

IN NO EVENT SHALL THE AUTHOR BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE AUTHOR SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE
AUTHOR HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.



=cut

__PACKAGE__->meta->make_immutable;

1;
