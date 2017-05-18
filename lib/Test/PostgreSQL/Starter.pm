package Test::PostgreSQL::Starter;


=head1 NAME

 Test::PostgreSQL::Starter - Start one or more PostgreSQL servers in the background
 
 $Id: Starter.pm 673 2017-05-12 13:01:01Z alvar $

=head1 VERSION

Version 0.5.x, $Revision: 567 $

=cut


=head1 SYNOPSIS

=encoding utf8

  use Test::PostgreSQL::Starter plan => 1;
  
  pg_initdb_ok();


=head1 DESCRIPTION

DOCUMENTATION PRE-PROD -- NOT ALL CORRECT!



This module helps to test PostgreSQL applications. It can initialize, 
start, stop and delete an arbitriary number of PostgreSQL instances 
(clusters), streaming replication masters and slaves etc.

After initialization it is possible to keep the cluster. With this it is 
possible, to run a lot of different test files to the running PostgreSQL 
servers without re-initialise them for every test. It's possible to 





############################################################################################################


Aktuelle Version: nimmt nur neustes Postgres; 

Später: macht das ganze auch Versionierbar!



Start & Stop eine bestimmte Version!



conf:

   name
   port
   pg_bindir
   pg_version    # später
   cluster_path
   




=cut

# Subroutine prototypes explicitely desired in Test::...-Modules!
## no critic (Subroutines::ProhibitSubroutinePrototypes)


use strict;
use warnings;

use 5.010;                                         # uses some 5.10 features

#<<<
my $BASE_VERSION = "0.1"; use version; our $VERSION = qv( sprintf "$BASE_VERSION.%d", q$Revision: 609 $ =~ /(\d+)/xg );
#>>>


use English qw( -no_match_vars );
use FindBin qw($Bin);
use List::Util qw(first);
use Carp;
use Readonly;
use IO::All;
use File::Path qw(make_path remove_tree);
use Config::Tiny;

use parent 'Test::Builder::Module';

our @EXPORT = qw( pg_binary_ok
   pg_read_conf_ok
   pg_initdb_ok      pg_initdb_unless_exists_ok
   pg_dropcluster_ok pg_dropcluster_if_exists_ok
   pg_start_ok       pg_stop_ok
   pg_stop_all_ok
   );


use constant DEFAULT_PORT => 15432;                ## no critic (ValuesAndExpressions::RequireNumberSeparators)


my %conf;

# NO!
# => use import_extra

#sub import
#   {
#   my $class = shift;
#   %conf = @ARG;
#   }



# PG search paths, partly borrowed from Test::PostgreSQL
my @search_paths = grep { -d } (
   split( /:/, $ENV{PATH} ),

   # popular installation dir?
   qw(/usr/local/pgsql/bin /usr/local/pgsql),

   # ubuntu, debian; order by version
   ( reverse sort glob "/usr/lib/postgresql/*/bin" ),

   # macport
   ( reverse sort glob "/opt/local/lib/postgresql*/bin" ),

   # Postgresapp.com
   ( reverse sort glob "/Applications/Postgres.app/Contents/Versions/*" ),

   # BSDs and others;
   "/usr/local/bin",
                               );

unshift @search_paths, $ENV{PGBINDIR} if $ENV{PGBINDIR};

## This config or environment variable is used to override the default, so it gets
## prefixed to the start of the search paths.
#my $my_pg_home = $conf{pg_bindir} // $ENV{POSEMO_PGBINDIR};
#unshift @search_paths, $my_pg_home if $my_pg_home;
#
## complete binary paths
#my $pg_ctl = first { -x } map { "$ARG/pg_ctl" } @search_paths;
#my $initdb = first { -x } map { "$ARG/initdb" } @search_paths;


#
# _get_initdb, _get_pg_ctl
# Gets complete paths to execdutable
#
#

sub _get_binary
   {
   my $conf = shift // {};
   my $bin = shift;

   my @local_search_paths = @search_paths;
   my $my_pg_home         = $conf{pg_bindir};
   unshift @local_search_paths, $my_pg_home if $my_pg_home;

   my $found = first { -x } map { "$ARG/$bin" } @local_search_paths;

   return $found;
   }


sub _build_conf
   {
   my $conf = shift // { name => "unnamed" };

   $conf = { name => $conf } unless ref $conf;
   $conf->{port} //= DEFAULT_PORT;
   $conf->{cluster_path} //= $ENV{POSTGRES_TEST_DIR} // "/tmp/_test-postgresql-starter";

   return $conf;
   }



## Other config
#my $conf->{cluster_path} = $conf{postgres_test_dir} // $ENV{POSTGRES_TEST_DIR} // "/tmp/_test-postgresql-starter";
#
## Not Readonly, the number may change!
#my $port = $conf{postgres_port} // $ENV{POSTGRES_PORT} // 15432;                            ## no critic
#
#


=head1 TESTS

=head2 summary:

OLD API with name instead of conf


 * pg_binary_ok($message)
 * pg_initdb_ok($name, $is_master, $initdb_params, $config, $message)
 * pg_initdb_unless_exists_ok($name, $is_master, $initdb_params, $config, $message)
 * pg_dropcluster_ok($name, $message)
 * pg_dropcluster_if_exists_ok($name, $message)
 * pg_start_ok($name, $message) (undef: all)
 * pg_stop_ok($name, $message) (undef: all)
 * pg_temp_config_ok($name, $config)
 * pg_get_dsn_ok($name, $config)


=head2 pg_binary_ok( [ $conf, $message ] )

Not really a test; just returns OK if pg_ctl and initdb exists
This test fails, if the binaries are not found.


=cut

sub pg_binary_ok(;$$)
   {
   my $conf = shift // _build_conf();
   my $msg  = shift // "found pg_ctl and initdb binaries";

   my $tb = __PACKAGE__->builder;

   my $pg_ctl = _get_binary( $conf, "pg_ctl" );
   my $initdb = _get_binary( $conf, "initdb" );

   if ( $pg_ctl and $initdb )
      {
      $tb->ok( 1, $msg );
      return 1;
      }

   $tb->ok( 0, $msg );
   $tb->diag("pg_ctl binary not found") unless $pg_ctl;
   $tb->diag("initdb binary not found") unless $initdb;
   $tb->diag("Paths, searched for the binaries: @search_paths");

   return 0;
   } ## end sub pg_binary_ok(;$$)



=head2 pg_read_conf_ok($name)

Reads and returns a stored config

=cut


sub pg_read_conf_ok(;$$)
   {
   my $name = shift;
   my $message = shift // "Read conf <$name>";

   my $pathconf = _build_conf($name);

   my $conf = Config::Tiny->read("$pathconf->{cluster_path}/$pathconf->{name}/_test-postgresql-starter.conf");

   my $tb = __PACKAGE__->builder;

   $tb->ok( $conf, $message );
   $tb->diag( "Error message from Config::Tiny: " . Config::Tiny->errstr ) unless $conf;

   return $conf->{_};
   }


#
# internal:
# saves an config for later reuse
#

sub _write_conf
   {
   my $conf = shift;

   my $out = Config::Tiny->new;
   $out->{_} = $conf;
   my $status = $out->write("$conf->{cluster_path}/$conf->{name}/_test-postgresql-starter.conf");

   unless ($status)
      {
      my $tb = __PACKAGE__->builder;
      $tb->diag( "Error while writing conf: " . Config::Tiny->errst );
      }

   return $status;
   }



=head2 pg_initdb_ok($conf|$name, [ $has_replication, $initdb_params, $config, $message ])

Initialises a new PostgreSQL testing cluster with the name $name.

The cluster will be stored in a subirectory named C<$name> in the test 
directory. The test directory is usually a directory named C<_test-postgresql-starter-tmp> 
in the directory of the running binary (usually t).

You may override this by setting the environment variable C<$ENV{POSTGRES_TEST_DIR}>
The main directory for the clusters will be created, when not exists -- but 
the test fails, when inside is an existing directory with C<$name>. 
You may want to use pg_initdb_unless_exists_ok instead.

Parameters:

=over 4

=item C<$name>

The name of the cluster, e.g. "master". Mandatory.

=item C<$has_replication> 

Flag, if streaming replication will enabled an if this cluster will be 
master or slave. 

When false, no streaming replication is autmatically configured.

When true, this instance will configured with streaming replication 
enabled. With positive value as master.

When negative value (-1), then this cluster is a streaming replication B<slave,> 
which needs a previously defined master.

=item C<$initdb_params>

Parameter for initdb. Default: C<-E UTF8>

=item C<$config>

Additional text for the C<postgresql.conf>. This text will be appended on the end 
of the config and overwrites all other configs.

=item C<$message>

Message for the test, if you want a non default message.

=back

=cut

sub pg_initdb_ok($;$$$$)
   {
   my $conf            = _build_conf(shift);
   my $has_replication = shift // 0;
   my $initdb_params   = shift // "-E UTF8";
   my $config          = shift // "";
   my $message         = shift // "Creating PostgreSQL cluster '$conf->{name}'";

   my $tb = __PACKAGE__->builder;

   if ( -d "$conf->{cluster_path}/$conf->{name}" )
      {
      $tb->ok( 0, $message );
      $tb->diag("Cluster '$conf->{name}' exists: Directory '$conf->{cluster_path}/$conf->{name}' exists!");
      return 0;
      }

   make_path("$conf->{cluster_path}/$conf->{name}");

   my $initdb = _get_binary( $conf, "initdb" );
   my $state
      = system(
      "$initdb -D '$conf->{cluster_path}/$conf->{name}' $initdb_params 1>$conf->{cluster_path}/stdout.log 2>$conf->{cluster_path}/stderr.log"
      );

   if ($state)
      {
      my $rc = $tb->ok( 0, $message );
      $tb->diag("Error while calling initdb. RC: $rc. OS_ERROR: $OS_ERROR");
      $tb->diag("Check $conf->{cluster_path}/stdout.log and $conf->{cluster_path}/stderr.log");
      return 0;
      }

   unlink "$conf->{cluster_path}/stdout.log", "$conf->{cluster_path}/stderr.log"
      or warn "UPS? Error when deleting redirection files: $OS_ERROR\n";

   #make_path("/$conf->{cluster_path}/sockets");

   my $extra_config = <<"CONF_END";

#
# *** Extra Config from Test::PostgreSQL::Starter
#

lc_messages             = 'C'                       # (error) Messages always in english

port                    = $conf->{port}
shared_buffers          = 1MB                       # 1 MB for old shared mem OS X // usually enough for testing; overwrite with more on bigger DBs
fsync                   = off                       # WOOOH! ONLY FOR TESTING! In testing mode we usually need no fsync.


CONF_END

   $extra_config .= <<"END_OF_CONF" if $has_replication;

wal_level       = hot_standby
max_wal_senders = 5 


END_OF_CONF

   $extra_config .= "\n\n# *** Extra user config\n\n$config\n";
   $extra_config >> io("$conf->{cluster_path}/$conf->{name}/postgresql.conf");

   my $port_master = "";                           #### TODO: MACHEN!

   <<"END_OF_CONF" > io("$conf->{cluster_path}/$conf->{name}/recovery.conf") if $has_replication < 0;

standby_mode = 'on'
recovery_target_timeline = 'latest'
primary_conninfo = 'port=$conf{port_master} user=postgres application_name=.........'

END_OF_CONF

   _write_conf($conf);

   $tb->ok( 1, $message );
   return 1;

   } ## end sub pg_initdb_ok($;$$$$)


=head2 pg_initdb_unless_exists_ok($name, $has_replication, $initdb_params, $config, $message)

The same as pg_initdb_ok, but does not fail if cluster exists 

=cut

sub pg_initdb_unless_exists_ok($;$$$$)
   {
   my $conf            = _build_conf(shift);
   my $has_replication = shift;
   my $initdb_params   = shift;
   my $config          = shift;
   my $message         = shift // "Creating PostgreSQL cluster '$conf->{name}' unless exists";

   if ( -d "$conf->{cluster_path}/$conf->{name}" )
      {
      __PACKAGE__->builder->ok( 1, "$message (cluster exists!)" );
      return 1;
      }

   return pg_initdb_ok( $conf->{name}, $has_replication, $initdb_params, $config, $message );

   }


# * pg_dropcluster_ok($name, $message)
# * pg_dropcluster_if_exists_ok($name, $message)


=head2 pg_dropcluster_ok($name, $message)

Drops a named cluster

=cut

sub pg_dropcluster_ok($;$)
   {
   my $conf = _build_conf(shift);
   my $message = shift // "Dropping cluster $conf->{name}";

   my $tb = __PACKAGE__->builder;

   unless ( -d "$conf->{cluster_path}/$conf->{name}" )
      {
      $tb->ok( 0, $message );
      $tb->diag("Cluster '$conf->{name}' does not exist: Directory '$conf->{cluster_path}/$conf->{name}' does not exist!");
      return 0;
      }

   if ( -d "$conf->{cluster_path}/$conf->{name}/postmaster.pid" )
      {
      $tb->ok( 0, $message );
      $tb->diag(
         "Can't drop cluster '$conf->{name}', because postmaster running / PID file '$conf->{cluster_path}/$conf->{name}/postmaster.pid' exists."
      );
      return 0;
      }

   remove_tree( "$conf->{cluster_path}/$conf->{name}", { safe => 1 } );

   if ( -d "$conf->{cluster_path}/$conf->{name}" )
      {
      $tb->ok( 0, $message );
      $tb->diag("(Some parts of) Cluster '$conf->{name}' still exists after deleting.");
      return 0;
      }

   $tb->ok( 1, $message );

   return 1;
   } ## end sub pg_dropcluster_ok($;$)


=head2 pg_dropcluster_if_exists_ok($name, $message)

Drop a named cluster, but don't thow an failure if it exists.

=cut

sub pg_dropcluster_if_exists_ok($;$)
   {
   my $conf = _build_conf(shift);
   my $message = shift // "Dropping cluster $conf->{name}";

   unless ( -d "$conf->{cluster_path}/$conf->{name}" )
      {
      __PACKAGE__->builder->ok( 1, "$message (cluster does not exist)" );
      return 1;
      }

   return pg_dropcluster_ok( $conf->{name}, $message );
   }


# * pg_start_ok($name, $message) (undef: all)
# * pg_stop_ok($name, $message) (undef: all)


=head2 pg_start_ok($name, $message)

starts the cluster $name

=cut

sub pg_start_ok(;$$)
   {
   my $conf = _build_conf(shift);
   my $message = shift // "Start Server $conf->{name}";

   my $tb = __PACKAGE__->builder;

   my $pg_ctl = _get_binary( $conf, "pg_ctl" );

   # $tb->diag("$pg_ctl -D '$conf->{cluster_path}/$conf->{name}' start 1>$conf->{cluster_path}/stdout.log 2>$conf->{cluster_path}/stderr.log");
   my $state
      = system(
      "$pg_ctl -D '$conf->{cluster_path}/$conf->{name}' start 1>$conf->{cluster_path}/stdout.log 2>$conf->{cluster_path}/stderr.log"
      );

   if ($state)
      {
      my $rc = $state >> 8;                        ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
      $tb->ok( 0, $message );
      $tb->diag("Error while calling pg_ctl -D '$conf->{cluster_path}/$conf->{name}' start. RC: $rc. OS_ERROR: $OS_ERROR");
      $tb->diag("Check $conf->{cluster_path}/stdout.log and $conf->{cluster_path}/stderr.log");
      return 0;
      }

   unlink "$conf->{cluster_path}/stdout.log", "$conf->{cluster_path}/stderr.log"
      or warn "UPS? Error when deleting redirection files: $OS_ERROR\n";

   $tb->ok( 1, $message );

   return 1;
   } ## end sub pg_start_ok(;$$)


=head2 pg_stop_ok($name $message)

Stops the cluster $name

=cut

sub pg_stop_ok(;$$)
   {
   my $conf = _build_conf(shift);
   my $message = shift // "Stopping Clusrer '$conf->{name}'";

   my $tb = __PACKAGE__->builder;

   my $pg_ctl = _get_binary( $conf, "pg_ctl" );
   my $state
      = system(
      "$pg_ctl -D '$conf->{cluster_path}/$conf->{name}' stop -m fast 1>$conf->{cluster_path}/stdout.log 2>$conf->{cluster_path}/stderr.log"
      );

   if ($state)
      {
      my $rc = $state >> 8;                        ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
      $tb->ok( 0, $message );
      $tb->diag("Error while calling pg_ctl -D '$conf->{cluster_path}/$conf->{name}' stop -m fast. RC: $rc. OS_ERROR: $OS_ERROR");
      $tb->diag("Check $conf->{cluster_path}/stdout.log and $conf->{cluster_path}/stderr.log");
      return 0;
      }

   unlink "$conf->{cluster_path}/stdout.log", "$conf->{cluster_path}/stderr.log"
      or warn "UPS? Error when deleting redirection files: $OS_ERROR\n";

   $tb->ok( 1, $message );

   return 1;
   } ## end sub pg_stop_ok(;$$)



=head2 pg_stop_all_ok()

Stopps all running clusters

=cut

sub pg_stop_all_ok(;$)
   {
   my $message = shift // "Stopping all Clusters";
   my $ok = 1;

   my $tb = __PACKAGE__->builder;

   foreach my $cluster ( _all_cluster() )
      {
      my $conf = _read_conf($cluster);
      my $pg_ctl = _get_binary( $conf, "pg_ctl" );
      my $state
         = system(
         "$pg_ctl -D '$conf->{cluster_path}/$cluster' stop -m fast 1>$conf->{cluster_path}/stdout.log 2>$conf->{cluster_path}/stderr.log"
         );

      if ($state)
         {
         my $rc = $state >> 8;                     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
         $tb->diag("Error while calling pg_ctl -D '$conf->{cluster_path}/$cluster' stop -m fast. RC: $rc. OS_ERROR: $OS_ERROR");
         $tb->diag("Check $conf->{cluster_path}/stdout.log and $conf->{cluster_path}/stderr.log");
         $ok = 0;
         }
      }

   $tb->ok( $ok, $message );
   return $ok;

   } ## end sub pg_stop_all_ok(;$)

sub _all_cluster
   {
   return grep { -d } glob("cluster_path/*");
   }


=head1 CONFIGURATION




Following text is WRONG!!!!!!




There are some configuration parameters. This can be set via import 
or as environment variables:

  use Test::PostgreSQL::Starter (postgres_path => "/my/special/path", postgres_port => 5678);
  
  # OR:
  
  BEGIN { $ENV{POSTGRES_PATH} = "/my/special/path"; }
  use Test::PostgreSQL::Starter;

Environment variables must be written all in CAPS, import parameter all in small.

The following parameters can be used:

C<postgres_path:> Extra search path to the PostgreSQL binaries (pg_ctl and initdb).

C<postgres_test_dir:> Path, where the PostgreSQL clusters will be created. 
Default: /tmp/_test-postgresql-starter

C<postgres_port:> Base port for the first PostgreSQL instance; if there are more 
then one, the port will be incremented.


Because this Module is only for testing and development, it does not configure any 
restrictions in pg_hba.conf, so usually all local users are trusted. 


=head1 AUTHOR

Alvar C.H. Freude, C<< <"alvar at a-blast.org"> >>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT


=cut

1;

