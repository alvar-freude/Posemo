package PostgreSQL::SecureMonitoring::App;

use Moose;
use 5.010;


=head1 NAME

 PostgreSQL::SecureMonitoring::App - Application class for PostgreSQL Secure Monitoring


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






Extra Checks für HostGroups:

  * Kriegen eine Liste an Hosts, das sind check-Objete für jeden Host!
  * ermitteln dann da Zeug 


# check: http://search.cpan.org/~mbp/Data-Processor-0.4.3/lib/Data/Processor.pm
# Check: http://search.cpan.org/~sonnen/Data-Validate-0.09/Validate.pm
# check: http://search.cpan.org/~cmo/Config-Validate-0.2.6/lib/Config/Validate.pm



=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);

use Config::Any;

use Config::FindFile qw(search_conf);

use Log::Log4perl::EasyCatch log_config => search_conf("posemo-logging.properties");
use PostgreSQL::SecureMonitoring;



use Moose;

#<<<

has configfile => ( is => "ro", isa => "Str",       default => search_conf("posemo.conf"),               documentation => "Configuration file", );
has log_config => ( is => "rw", isa => "Str",                                                            documentation => "Alternative logging config", );
has conf       => ( is => "ro", isa => "HashRef[]", builder => "_build_conf",                            documentation => "Complete configuration (usually don't use at CLI)", );

#>>>

with "MooseX::Getopt";
with 'MooseX::ListAttributes';



sub BUILD
   {
   my $self = shift;

   # manually handle logging conf attribute:
   # CLI has prio; when not set, set attribute via configfile
   $self->log_config( $self->conf->{log_config} ) if ( not $self->log_config ) and $self->conf->{log_config};

   # Re-Init loggig, if the above results in an alternative log config beside the default
   if ( $self->log_config ne $DEFAULT_LOG_CONFIG )
      {
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
   my $conf = Config::Any->load_files( { files => [ $self->configfile ], use_ext => 1, flatten_to_hash => 1 } );

   $conf = $conf->{ $self->configfile };

   use Data::Dumper;
   TRACE "Conf: ", Dumper($conf);

   # TODO: validate!
   return $conf;
   }



1;
