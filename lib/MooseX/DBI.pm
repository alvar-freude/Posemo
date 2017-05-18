package MooseX::DBI;

use Moose::Role;
use DBI;

=head1 NAME

 MooseX::DBI -- DBI connection role for Moose

=head1 VERSION

Version 0.5.0

=cut

use version; our $VERSION = qv("v0.5.0");


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

has dbh => ( is => "ro", isa => "DBI::db", lazy_build => 1, handles => [qw(rollback)] );
has _committed => ( is => "rw", isa => "Bool", );
has _is_my_dbh => ( is => "rw", isa => "Bool", );

requires qw(dbi_dsn dbi_user dbi_passwd dbi_options);


sub _build_dbh
   {
   my $self = shift;

   my $dbh = DBI->connect_cached( $self->dbi_dsn, $self->dbi_user, $self->dbi_passwd, $self->dbi_options )
      or die "Can't get DB handle: $DBI::errstr\n";

   $self->_is_my_dbh(1);

   #   my $ping = $dbh->ping;
   #   warn "Ping-result: $ping\n";

   return $dbh;
   }


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


=head2 get_all_from($table, $order_column, @columns)

gibt alle Zeilen einer Tabelle zurück, die angegebenen Spalten

=cut


sub get_all_from
   {
   my ( $self, $table, $order, @columns ) = @_;

   my $where = "";
   if ( $columns[0] eq "where" )
      {
      shift @columns;
      $where = " WHERE " . shift @columns;
      }

   my $sth = $self->dbh->prepare_cached( "SELECT " . join( ", ", @columns ) . " FROM $table$where ORDER BY $order;" );

   my %row;

   $sth->execute;
   $sth->bind_columns( map { \$row{$_} } @columns );

   my @result;


   push @result, {%row} while $sth->fetch;

   return \@result;

   } ## end sub get_all_from


=head2 ->update_table()

   $self->update_table(
                        table        => "wahl_kandidaten",
                        where        => "id = ?",
                        where_params => [ $kandidat->{id} ],
                        columns      => [qw( titel vorname name geschlecht jahrgang partei_id wahlkreis listenplatz motto )],
                        data         => $fdat,
                      );

=cut


sub update_table
   {
   my ( $self, %params ) = @_;

   #   use Data::Dumper;
   #   warn Dumper \%params;

   my $set = join( ", ", map { "$_ = ?" } @{ $params{columns} } );    ## no critic (NamingConventions::ProhibitAmbiguousNames)
   $set .= ", $params{extra_set}" if $params{extra_set};

   my $sth;

   if ( $params{noprepare} )
      {
      $sth = $self->dbh->prepare( "UPDATE $params{table} SET $set WHERE $params{where}", { pg_server_prepare => 0 } );
      }
   else
      {
      $sth = $self->dbh->prepare_cached("UPDATE $params{table} SET $set WHERE $params{where}");
      }

   $sth->execute( @{ $params{data} }{ @{ $params{columns} } }, @{ $params{where_params} } );

   return $self;
   } ## end sub update_table


=head2 ->numify($data_hashref, @values)

makes strings from some values ...

=cut

sub numify
   {                                               ## no critic (Subroutines::RequireArgUnpacking)
   my $self = shift;
   my $data = shift;

   foreach my $key (@_)
      {
      next unless defined $data->{$key};
      if ( $data->{$key} eq "" )
         {
         $data->{$key} = undef;
         next;
         }
      $data->{$key} += 0;
      }

   return $self;
   }


1;
