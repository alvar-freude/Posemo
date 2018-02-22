package MooseX::DBI;

use Moose::Role;
use DBI;

=head1 NAME

 MooseX::DBI -- DBI connection role for Moose

=head1 VERSION

Version 0.5.0

=cut

use version; our $VERSION = qv("v0.5.0");

#use English qw( -no_match_vars );


=head1 SYNOPSIS

=encoding utf8

 with MooseX::DBI;
 # [...] later
 
 $self->dbh->do("INSERT INTO test VALUES (1,2,3);");
 $self->commit;
 
 # or, when failed:
 $self->rollback;

=head1 DESCRIPTION

This role provides cached DBI handles.

[...] (doc TODO)


=cut

#<<< no perltidy

has _dbh       => ( reader => "dbh", is => "ro", isa => "DBI::db", lazy_build => 1, handles => [qw(rollback)], predicate => "has_dbh", );
has _committed => (                  is => "rw", isa => "Bool", );
has _is_my_dbh => (                  is => "rw", isa => "Bool", );

#>>> no perltidy

requires qw(dbi_dsn dbi_user dbi_passwd dbi_options);


sub _build__dbh
   {
   my $self = shift;

   my $dbh;
   eval {
      if ( $self->dbi_dsn eq q{-} )
         {
         # Dummy connection: prints everything to STDOUT!
         # TODO!
         die "TODO: build pseudo DBI object for printing to STDOUT ...\n";
         }
      else
         {
         $dbh = DBI->connect_cached( $self->dbi_dsn, $self->dbi_user, $self->dbi_passwd, $self->dbi_options );
         }
      return 1;
      }
      or die "Can't get DB handle: $DBI::errstr\n";

   $self->_is_my_dbh(1);

   #   my $ping = $dbh->ping;
   #   warn "Ping-result: $ping\n";

   return $dbh;
   } ## end sub _build__dbh


=head2 ->commit

macht ein Commit und setzt das Flag, dass committet ist!
Wenn mehrere transaktionen pro Query stattfinden, muss das wieder zurückgesetzt werden,
sonst kommt kein Rollback am Ende, was dazu führt dass es auf den nächsten Query wartet!

=cut

sub commit
   {
   my $self = shift;

   $self->dbh->commit;
   $self->_committed(1);

   return $self;
   }


=head2 ->begin

Cleans the "committed"-flag, marks everything as not committed.

DBI starts transaction by itself.

=cut

sub begin
   {
   my $self = shift;
   $self->_committed(0);
   return $self;
   }

=head2 DEMOLISH

Destructor for Moose; rollback DB unless committed

=cut

sub DEMOLISH
   {
   my $self = shift;

   # Kein ROllback wenn schon Commit oder es ein übergebenes Handle ist
   return if $self->_committed or not $self->_is_my_dbh;
   $self->rollback if $self->has_dbh;

   return;
   }



1;
