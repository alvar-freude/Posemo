package PostgreSQL::SecureMonitoring::Install;

use Moose;
use 5.010;

=head1 NAME

 PostgreSQL::SecureMonitoring::Install - Install all functions from all Checks etc.

=head1 SYNOPSIS

=encoding utf8

  use PostgreSQL::SecureMonitoring::Install;
  
  my $install = PostgreSQL::SecureMonitoring::Install


=head1 DESCRIPTION

This module provides everything for installing Posemo: 
It installs (optionally) all needed users and the database, SQL-Schema and
all checks.

run via: C<posemo_install.pl>


TODO: docs cleanup!

TODO: 
generate SQL output instead of directly connecting to DB! 
For this, wrap dbh object in other class, outputs the SQL in do-method and handles begin/commit!



=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);

use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf("posemo-logging.properties") );

use Moose;
extends "PostgreSQL::SecureMonitoring";

=head1 METHODS

=head2 new

Creates a new installer object. The same attributes as PostgreSQL::SecureMonitoring, 
with the following additional attributes:

=head3 Attributes

=over 4

=item create_database

Flag (Boolean), indicating if the monitoring database should be created. Needs 
a C<admin_database> and C<connect_user> for connecting (see below).

=item drop_database

Flag (Boolean), indicating if an old monitoring database should be deleted.

C<DROP DATABASE> is calles with C<IF EXISTS>, so this will be ignored when no 
old database is available.

=item create_user

Flag (Boolean), indicating if the (unprivileged) monitoring user should be created.

=item create_superuser

Flag (Boolean), indicating if the monitoring superuser should be created.

=item create_schema

Flag (Boolean), indicating if schema for all monitoring objects should be created.

Will be created with C<IF NOT EXISTS>

=item installation_user

Name of the connecting admin user used for superuser and database database creation, 
default undef (current user).

Only used when necessary.


=item installation_passwd

Password of this user, default undef.

=item installation_database

Name of the connecting admin database used for creation of superuser and database; default: postgres.

Only used when necessary.

=back

=cut

#<<< no perltidy

has superuser             => ( is => "ro", isa => "Str",  default => "posemo_admin",     documentation => "Owner of check functions (ususally a superuser)" );
has create_database       => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: create new DB", );
has drop_database         => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: drop old DB if exist", );
has create_user           => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: create monitoring user", );
has drop_user             => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: drop user before creating, if exist", );
has create_superuser      => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: create monitoring superuser", );
has create_schema         => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: create SQL schema", );
has drop_schema           => ( is => "ro", isa => "Bool", default => 0,                  documentation => "Flag: drop SQL schema (before creating)", );
has installation_user     => ( is => "ro", isa => "Str",                                 documentation => "User for creating superuser", );
has installation_passwd   => ( is => "ro", isa => "Str",                                 documentation => "Password for the connect_user", );
has installation_database => ( is => "ro", isa => "Str",  default => "postgres",         documentation => "Connect DB for admin", );

#>>> no perltidy

with "MooseX::Getopt::Dashes";
with 'MooseX::ListAttributes';


use Readonly;

Readonly my $VERSION_HAS_MONITORING_ROLE => 10_00_00;    # 10.0


=head2 install

installs database and all checks

=cut

sub install
   {
   my $self = shift;

   return $self->list_attributes if $self->show_options;

   my $installed_non_rollbackable = 0;
   INFO "Install Posemo and Checks";
   if ( $self->create_database )
      {
      eval { return $self->install_basics; }
         or die "ERROR creating Database: $EVAL_ERROR.\nAttention: Can not rollback already created objects!\n";
      $installed_non_rollbackable = 1;
      }

   eval {
      # Transaction starts here!

      # $self->dbh->do("SET search_path TO ${ \$self->schema }");

      $self->_do_create_user if $self->create_user;
      $self->_do_create_superuser() if $self->create_superuser;

      if ( $self->create_database )
         {
         TRACE "Clean up owner and permissions of created database";
         $self->dbh->do("ALTER          DATABASE ${ \$self->database } OWNER TO ${ \$self->superuser };");
         $self->dbh->do("REVOKE ALL  ON DATABASE ${ \$self->database } FROM PUBLIC;");
         }
      $self->dbh->do("GRANT  CONNECT ON DATABASE ${ \$self->database } TO ${ \$self->user }");

      $self->_do_install_schema if $self->create_schema;

      INFO "Install all check functions";
      $self->install_checks;
      TRACE "install check functions done";

      return $self->commit;
      } or do
      {
      $self->rollback;
      my $rb_extra = $installed_non_rollbackable ? ", but database and superuser creation not rollbackable!" : " everything!";
      die "ERROR creating posemo checks etc: $EVAL_ERROR. ROLLBACK$rb_extra\n";
      };

   INFO "Posemo installed.";

   return 1;
   } ## end sub install

=head2 install_basics

Installs basic objects, that must be created with other connection.

Currently this is only the database.

=cut

sub install_basics
   {
   my $self = shift;

   # Extra installs: superuser, database
   # no ROLLBACK possible!
   my $dsn = $self->dbi_dsn;

   $dsn =~ s{dbname=\w+}{dbname=${ \$self->installation_database }}msx;

   $self->_do_create_database($dsn) if $self->create_database;

   return 1;
   }

=head2 install_checks

Installs all available checks. 

This methid searches for all check modules in all @INC paths, 

=cut

sub install_checks
   {
   my $self = shift;

   INFO "Install all checks";
   my @checks = $self->get_all_checks();
   TRACE "Checks: " . join( " - ", @checks );
   foreach my $check_name (@checks)
      {
      INFO "  => Check $check_name";
      my $check = $self->new_check($check_name);
      $check->install;
      }

   return 1;
   }

sub _do_drop_user
   {
   my $self = shift;

   INFO "INSTALL: drop monitoring user '${ \$self->user }', but only if exists";
   $self->dbh->do("DROP USER IF EXISTS ${ \$self->user };");
   $self->dbh->do("DROP USER IF EXISTS ${ \$self->superuser };") if $self->create_superuser;
   DEBUG "drop user done";

   return $self;
   }

sub _do_create_user
   {
   my $self = shift;

   $self->_do_drop_user if $self->drop_user;

   INFO "INSTALL: create monitoring user '${ \$self->user }'";
   $self->dbh->do("CREATE USER ${ \$self->user };");
   $self->dbh->do("ALTER USER ${ \$self->user } SET search_path TO ${ \$self->schema };");
   DEBUG "create user done";

   return $self;
   }

sub _do_create_superuser
   {
   my $self = shift;

   my $role_string;
   if   ( $self->server_version >= $VERSION_HAS_MONITORING_ROLE ) { $role_string = "IN ROLE pg_monitor"; }
   else                                                           { $role_string = "SUPERUSER"; }

   INFO "INSTALL: create monitoring superuser '${ \$self->superuser }'";
   $self->dbh->do("CREATE ROLE ${ \$self->superuser } NOLOGIN $role_string;");
   $self->dbh->do("ALTER USER ${ \$self->superuser } SET search_path TO ${ \$self->schema };");
   DEBUG "create user done";

   return $self;
   }

sub _do_drop_database
   {
   my $self = shift;
   my $dbh  = shift;

   INFO "INSTALL: drop monitoring database '${ \$self->database }', but only if exists";
   $dbh->do("DROP DATABASE IF EXISTS ${ \$self->database };");
   DEBUG "drop DB done";

   return $self;
   }

sub _do_create_database
   {
   my $self = shift;
   my $dsn  = shift;

   # Autocommit, because can't create databases in transactions
   my $dbh = DBI->connect( $dsn, $self->installation_user, $self->installation_passwd, { RaiseError => 1, AutoCommit => 1 }, );

   $self->_do_drop_database($dbh) if $self->drop_database;

   INFO "INSTALL: create monitoring database '${ \$self->database }'";
   $dbh->do("CREATE DATABASE ${ \$self->database };");

   # grants will be set later!

   DEBUG "create DB done";

   return $self;
   }

sub _do_install_schema
   {
   my $self = shift;
   INFO "Install Schema ${ \$self->schema };";

   my $revoke;
   if ( $self->schema eq "public" )
      {
      INFO "Schema is 'public', skippting REVOKE ALL ... FROM PUBLIC!";
      $revoke = "";
      }
   else
      {
      $revoke = "REVOKE ALL ON SCHEMA ${ \$self->schema } FROM PUBLIC;";
      }

   my $drop = $self->drop_schema ? "DROP SCHEMA IF EXISTS ${ \$self->schema };" : "";

   $self->dbh->do(
      qq{ 
      $drop
      CREATE SCHEMA IF NOT EXISTS ${ \$self->schema };
      ALTER  SCHEMA ${ \$self->schema } OWNER TO ${ \$self->superuser };
      $revoke
      GRANT  USAGE ON SCHEMA ${ \$self->schema } TO ${ \$self->user };
   }
                 );

   return $self;

   } ## end sub _do_install_schema

=head2 dbi_user, dbi_passwd

Overrides the user and passwd in PostgreSQL::SecureMonitoring: for 
installation we need the superuser!

=cut

sub dbi_user
   {
   my $self = shift;
   return $self->installation_user;
   }

sub dbi_passwd
   {
   my $self = shift;
   return $self->installation_passwd;
   }

=head1 AUTHOR

Alvar C.H. FReude, C<< <"alvar at a-blast.org"> >>


=head1 ACKNOWLEDGEMENTS


=cut

__PACKAGE__->meta->make_immutable;

1;

