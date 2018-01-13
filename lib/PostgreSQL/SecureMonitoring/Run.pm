package PostgreSQL::SecureMonitoring::Run;

use Moose;
use 5.010;


=head1 NAME

 PostgreSQL::SecureMonitoring::Run - Application/Execution class for PostgreSQL Secure Monitoring


=head1 SYNOPSIS

=encoding utf8

...


=head1 DESCRIPTION



=head2 Configuration

The config file is parsed via L<Config::Any|Config::Any> and therefore understands each supported config file format.
The following examples are writtem in the apache style format, parsed via L<Config::General|Config::General>.


  #
  # Example config file
  #

  # Default values, can be overwritten by Hostgroups (see below)
  # Definition of Hosts to monitor
  # eihter name ONE host:

  host = database.internal.project.tld

  # user      = monitoring                      # Monitoring user (unprivileged)
  # passwd    =                                 # Password for this user; default: empty
  # schema    = public                          # SQL schema name for our
  # database  = monitoring                      # Name of monitoring DB"
  # port      =                                 # Port number for server to monitor



  # or more complex definition with host groups
  <HostGroup Elephant>
    Order = 10                                  # Sort order for this group
    Hosts = loc1_db1 loc1_db2 loc2_db1 loc2_db2 # Short version for hosts, all with default parameters from above
  </HostGroup>

  <HostGroup Mammut>
    Order = 20
    <Hosts>
      host = loc1_db3
      port = 5433
      # ...
    </Hosts>
    <Hosts>
      host = loc1_db3
      port = 5434
      # ....
    </Hosts>

  </HostGroup>


  <HostGroup


The following options of Gonfig::General are enabled:

  -LowerCaseNames     => 1,
  -AutoTrue           => 1,
  -UseApacheInclude   => 1,
  -IncludeRelative    => 1,
  -IncludeDirectories => 1,
  -IncludeGlob        => 1,

So all options may be written in lowe/upper case mixed. If you use another config file format
(YAML, JSON, ...), then you should write all attribute names in lowercase.



Extra Checks für HostGroups:

  * Kriegen eine Liste an Hosts, das sind check-Objete für jeden Host!
  * ermitteln dann da Zeug


# check: http://search.cpan.org/~mbp/Data-Processor-0.4.3/lib/Data/Processor.pm
# Check: http://search.cpan.org/~sonnen/Data-Validate-0.09/Validate.pm
# check: http://search.cpan.org/~cmo/Config-Validate-0.2.6/lib/Config/Validate.pm



=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);
use Carp qw(croak);
use Storable qw(dclone);

use Config::Any;

use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf("posemo-logging.properties") );

use PostgreSQL::SecureMonitoring;



use Moose;
#<<<

# conf must be lazy, because in the builder must be called after initialization of all other attributes!

has configfile => ( is => "ro", isa => "Str",          default => search_conf("posemo.conf"),            documentation => "Configuration file", );
has log_config => ( is => "rw", isa => "Str",                                                              documentation => "Alternative logging config", );
has conf       => ( is => "ro", isa => "HashRef[Any]", builder => "_build_conf",              lazy => 1, documentation => "Complete configuration (usually don't use at CLI)", );

#>>>

with "MooseX::Getopt";
with 'MooseX::ListAttributes';



sub BUILD
   {
   my $self = shift;

   # Log config logic:
   #
   # When log_config set (via CLI or ->new parameter): take this!
   # When not: take from config file, if this exists.
   # When not: take nothing, and don't re-initialise below
   # never set an empty log_config!

   if ( not $self->log_config )
      {
      if ( $self->conf->{log_config} )
         {
         $self->log_config( $self->conf->{log_config} );
         TRACE "Use log config from main config file: " . $self->log_config;
         }
      }
   else
      {
      TRACE "Use log config from (CLI) parameter: " . $self->log_config;
      }

   # re-initialise logging, when log config is set and is not the default one
   if ( $self->log_config and $self->log_config ne $DEFAULT_LOG_CONFIG )
      {
      die "Given log-config ${ \$self->log_config } does not exist\n" unless -f $self->log_config;
      Log::Log4perl->init( $self->log_config );
      DEBUG "Logging initialised with non-default config " . $self->log_config;
      }
   else
      {
      DEBUG "Logging still initialised with default config: $DEFAULT_LOG_CONFIG.";
      }

   return $self;
   } ## end sub BUILD


#  _build_conf
# reads / initializes the config file

sub _build_conf
   {
   my $self = shift;

   DEBUG "load config file: ${ \$self->configfile }";
   my $conf = Config::Any->load_files(
                                       {
                                         files           => [ $self->configfile ],
                                         use_ext         => 1,
                                         flatten_to_hash => 1,
                                         driver_args     => {
                                                          General => {
                                                                       -LowerCaseNames     => 1,
                                                                       -AutoTrue           => 1,
                                                                       -UseApacheInclude   => 1,
                                                                       -IncludeRelative    => 1,
                                                                       -IncludeDirectories => 1,
                                                                       -IncludeGlob        => 1,
                                                                     }
                                                        }
                                       }
                                     );

   $conf = $conf->{ $self->configfile } or die "No config loaded, tried with ${ \$self->configfile }!\n";

   use Data::Dumper;
   TRACE "Conf: ", Dumper($conf);

   # TODO: validate!
   return $conf;
   } ## end sub _build_conf


=head2 run

Runs all tests! Takes them including parameters from config file.

=cut


sub run
   {
   my $self = shift;

   my @results;

   foreach my $host ( @{ $self->all_hosts } )
      {
      DEBUG "Prepare running all checks for host $host->{host} in hostgroup $host->{_hostgroup}";
      my %host_params = map { $ARG => $host->{$ARG} } grep { not m{^_} } keys %$host;
      my $posemo = PostgreSQL::SecureMonitoring->new(%host_params);

      my @hosts_results;

      # TODO: catch errors.
      # run all checks
      foreach my $check_name ( $posemo->get_all_checks_ordered() )
         {
         DEBUG "Prepare and run check $check_name";
         my $check = $posemo->new_check( $check_name, $host->{_check_params} );
         my $result = $check->run_check;

         push @hosts_results, $result;

         }

      push @results, { host => $host, results => \@results };

      # TODO: results as attribute with traits

      #       # .................
      #      $self->add_result( { host => $host, } )

      } ## end foreach my $host ( @{ $self...})

   return \@results;
   } ## end sub run


=head2 all_host_groups

Returns a list of all host groups in the config file, ordered by the "order" config option.

The array contains only the names of the groups

=cut

sub all_host_groups
   {
   my $self = shift;

   my $grp = $self->conf->{hostgroup};
   my @all_host_groups = sort { ( $grp->{$a}{order} // 0 ) <=> ( $grp->{$b}{order} // 0 ) } keys %$grp;

   return @all_host_groups;
   }


=head2 all_hosts

Returns a list of hashrefs with informations of all hosts in all host groups.

Each hashref contains everything for calling the ->new constructor. Keys beginning
with underscore are internals, e.g. special parameters for specific tests via
C<_check_params>.

It is a flat, "denormalised" list.
So it's easy to loop over all hosts and all checks and setup the constructor.


=cut

sub all_hosts
   {
   my $self = shift;

   TRACE "get all hosts";
   my $conf = $self->conf;

   # Default parameters for all hosts
   my %defaults = _parameter_for_one_host($conf);
   my @hosts;

   # main section of conf
   push @hosts, _create_hosts_conf( $conf->{hosts}, \%defaults ) if $conf->{hosts};

   # host group sections
   foreach my $group ( $self->all_host_groups )
      {
      TRACE "Next group: '$group'";
      my %group_defaults = _parameter_for_one_host( $conf->{hostgroup}{$group}, \%defaults, $group );
      push @hosts, _create_hosts_conf( $conf->{hostgroup}{$group}{hosts}, \%group_defaults, $group );
      }

   return \@hosts;
   } ## end sub all_hosts



my @host_options          = qw(user passwd schema database port enabled warning_level critical_level min_value max_value);
my @other_options         = qw(hosts hostgroup check order);
my %allowed_host_options  = map { $ARG => 1 } @host_options;
my %allowed_other_options = map { $ARG => 1 } @other_options;
my %allowed_options       = ( %allowed_host_options, %allowed_other_options );


sub _parameter_for_one_host
   {
   my $conf        = shift;
   my $defaults    = shift // {};
   my $hostgroup   = shift // "_GLOBAL";
   my $hostmessage = shift // "";

   $hostmessage = " and host '$hostmessage'" if $hostmessage;

   my %params = ( %{ dclone($defaults) }, _hostgroup => $hostgroup );

   foreach my $option ( keys %$conf )
      {
      TRACE "Config option '$option' for hostgroup '$hostgroup'$hostmessage";
      die "Unknown or not allowed option '$option' in hostgroup '$hostgroup'$hostmessage\n"
         unless $allowed_options{$option};
      $params{$option} = $conf->{$option} if $allowed_host_options{$option};
      }

   # set all check options without test if they are allowed here.
   @{ $params{_check_params} }{ keys %{ $conf->{check} } } = @{ $conf->{check} }{ keys %{ $conf->{check} } };

   return %params;
   } ## end sub _parameter_for_one_host



#
# _create_hosts_conf( $host_conf_entry, $defaults )
#
# $host_conf_entry may be a string (space delimetered) or a arrayref
#

sub _create_hosts_conf
   {
   my $host_conf_entry = shift;
   my $defaults        = shift;
   my $group           = shift;

   # handle something like: host = host1 host2 host3
   return _split_hosts( $host_conf_entry, $defaults ) unless ref $host_conf_entry;

   return map {                                    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
      {
         ( %$defaults, host => $ARG->{hosts}, _parameter_for_one_host( $ARG, $defaults, $group, $ARG->{hosts} ), )
      }
   } @$host_conf_entry;
   }


#
# simple variant: split a single host config line
# with one or more hosts, separated by whitespace
#

sub _split_hosts
   {
   my $host_conf_entry = shift;
   my $defaults        = shift;

   die "Don't separate host names via comma! (at '$host_conf_entry')\n" if $host_conf_entry =~ m{,};

   return map {                                    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
      { ( %$defaults, host => $_ ) }
   } split( qr{\s+}, $host_conf_entry );

   }

1;
