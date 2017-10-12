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

use Log::Log4perl::EasyCatch;

use Config::Validate;



use Moose;
has configfile => ( is => "ro", isa => "Str", default => "$Bin/../conf/posemo.conf", documentation => "Configuration file" );
has log_config => ( is => "ro", isa => "Str", default => $DEFAULT_LOG_CONFIG, documentation => "Alternative logging config" );

with "MooseX::Getopt";



1;
