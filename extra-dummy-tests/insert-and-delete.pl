#!/usr/bin/env perl

use strict;
use warnings;

use Time::HiRes qw(time);

use DBI;

use 5.010;

my $db = shift // "alvar";

my $_dsn = $ENV{DB_DSN} || "dbi:Pg:dbname=$db";

print "\n\nDB_DSN: $_dsn\n\n";


=head1 SQL

CREATE TABLE ins_del_test(id SERIAL NOT NULL PRIMARY KEY, some_num real NOT NULL default random(), text text);

=cut


use forks;


async { ins($_) } for 1 .. 5;
async { del() }->join;



sub ins
   {
   my $procnum = shift;
   my $dbh = get_dbh($_dsn);

   my $run = 0;


   my $sth_ins = $dbh->prepare("INSERT INTO ins_del_test (text) VALUES (?)");
   while (1)
      {
      $run++;

      my $num_ins = int( rand(15) );

      say "$procnum ($$): Insert $num_ins at run $run";

      for ( 1 .. $num_ins )
         {
         $sth_ins->execute("Dummy Text from Thread $procnum ($$), run $run($_) (1..$num_ins)");
         sleep 0.1;
         }

      $dbh->commit;

      sleep rand(3);

      }

   } ## end sub ins


sub del
   {
   my $dbh = get_dbh($_dsn);


   my $sth_get_ids = $dbh->prepare("SELECT id FROM ins_del_test LIMIT 100;");
   my $sth_delete  = $dbh->prepare("DELETE FROM ins_del_test WHERE id = ?");

   my $num_del = 0;

   while (1)
      {

      $num_del++;

      my $ids = $dbh->selectcol_arrayref($sth_get_ids);

      say "Runde $num_del bei Del, mit $#$ids Dels";

      foreach my $id (@$ids)
         {
         sleep rand(0.01);
         $sth_delete->execute($id);
         }

      $dbh->commit;

      sleep 0.5;

      } ## end while (1)

   } ## end sub del


sub get_dbh
   {
   my $dsn = shift;
   my $dbh = DBI->connect(
                           $dsn, "alvar", undef,
                           {
                              AutoCommit => 0,
                              RaiseError => 1,
                           }
                         )
      || die "Init-Fehler: $DBI::errstr";

   return $dbh;

   }
