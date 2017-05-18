#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use PostgreSQL::SecureMonitoring::Checks;


# plan tests => 7;

sub ok_cc2w
   {
   my $cc     = shift;
   my $wanted = shift;

   my $result = PostgreSQL::SecureMonitoring::Checks::_camel_case_to_words($cc);

   return ( is( $result, $wanted, "Camel Case converted $cc => $wanted" ) );
   }


ok_cc2w( "Simple",            "Simple" );
ok_cc2w( "CamelCase",         "Camel Case" );
ok_cc2w( "SimpleCamelCase",   "Simple Camel Case" );
ok_cc2w( "XMLCheck",          "XMLCheck" );
ok_cc2w( "XMLCheckSuper",     "XMLCheck Super" );
ok_cc2w( "SuperXMLCheck",     "Super XMLCheck" );
ok_cc2w( "Check4Dummy",       "Check 4 Dummy" );
ok_cc2w( "Check4dummy",       "Check 4dummy" );
ok_cc2w( "Check4DummyLong",   "Check 4 Dummy Long" );
ok_cc2w( "With123Number",     "With 123 Number" );
ok_cc2w( "With123NumberLong", "With 123 Number Long" );

throws_ok( sub { PostgreSQL::SecureMonitoring::Checks::_camel_case_to_words("Name_with_Underscore") },
           qr{Non-word characters in check name},
           "Camel Case converter detects _ as non-word char" );

# usually, it is not possible to have non-word-chars beside _ in a package name
# but checked anyway
throws_ok( sub { PostgreSQL::SecureMonitoring::Checks::_camel_case_to_words("Name,Name") },
           qr{Non-word characters in check name},
           "Camel Case converter detects , as non-word char" );

throws_ok( sub { PostgreSQL::SecureMonitoring::Checks::_camel_case_to_words("startsSmall") },
           qr{must start with uppercase letter},
           "Camel Case converter detects lower case start" );

throws_ok( sub { PostgreSQL::SecureMonitoring::Checks::_camel_case_to_words("123NumberStart") },
           qr{must start with uppercase letter},
           "Camel Case converter detects number start" );



done_testing();


