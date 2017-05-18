package PostgreSQL::SecureMonitoring::App;

use Moose;
use 5.010;


=head1 NAME

 PostgreSQL::SecureMonitoring::App - Application class for PostgreSQL Secure Monitoring

 $Id: App.pm 669 2016-11-24 16:19:30Z alvar $

=head1 VERSION

Version 0.2.x, $Revision: 669 $

=cut

#<<<
my $BASE_VERSION = "0.1"; use version; our $VERSION = qv( sprintf "$BASE_VERSION.%d", q$Revision: 669 $ =~ /(\d+)/xg );
#>>>


=head1 SYNOPSIS

=encoding utf8

...


=head1 DESCRIPTION



Config with Config::General.


  #
  # Example config file
  #



  Default values, can be overwritten by Hostgroups (see below)
  # Definition of Hosts to monitor
  # eigther name ONE host:
  
  host = database.internal.project.tld

  # user      = monitoring                      # Minitoring user (unprivileged)
  # passwd    =                                 # Password for this user; default: empty
  # schema    = public                          # SQL schema name
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




=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);

use Log::Log4perl::EasyCatch;


use Moose;



1;
