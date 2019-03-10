#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use PostgreSQL::SecureMonitoring::Install;


my @to_test = (
   [ "SELECT 1;\n"    => "SELECT 1;\n" ],
   [ "SELECT 1;"      => "SELECT 1;\n" ],
   [ "SELECT 1"       => "SELECT 1;\n" ],
   [ "SELECT 1 "      => "SELECT 1; \n" ],         # 4
   [ "SELECT 1; "     => "SELECT 1; \n" ],
   [ "SELECT 1\n"     => "SELECT 1;\n" ],          # 6
   [ "SELECT 1\n "    => "SELECT 1;\n " ],
   [ "SELECT 1 ;  "   => "SELECT 1 ;  \n" ],
   [ "SELECT 1 ; \n"  => "SELECT 1 ; \n" ],
   [ "SELECT 1  \n  " => "SELECT 1;  \n  " ],      # 10
   [
      "SELECT 1; 
       SELECT 2;
       SELECT 3;" => "SELECT 1; 
       SELECT 2;
       SELECT 3;\n"
   ],
   [
      "SELECT 1; 
       SELECT 2;
       SELECT 3;\n" => "SELECT 1; 
       SELECT 2;
       SELECT 3;\n"
   ],
   [
      "SELECT 1; 
       SELECT 2;
       SELECT 3" => "SELECT 1; 
       SELECT 2;
       SELECT 3;\n"
   ],
   [
      "SELECT 1; 
       SELECT 2;
       SELECT 3 " => "SELECT 1; 
       SELECT 2;
       SELECT 3; \n"
   ],
   [
      "SELECT 1; 
       SELECT 2;
       SELECT 3 \n" => "SELECT 1; 
       SELECT 2;
       SELECT 3; \n"
   ],
);


foreach my $test (@to_test)
   {
   my ( $in, $expected ) = @$test;
   my $out = PostgreSQL::SecureMonitoring::Install::_end_query($in);
   is( $out, $expected, "Ergebnis für '$in'" );
   }


done_testing();

