#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;

use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";


throws_ok { check_has(); } qr{needs key-value pairs as parameters}, "no parameter to check_has";
throws_ok { check_has(1); } qr{needs key-value pairs as parameters}, "invalid parameter 1";
throws_ok { check_has( 1, 2, 3 ); } qr{needs key-value pairs as parameters}, "invalid parameter 1, 2, 3";


throws_ok { check_has( test => "invalid" ); } qr{Attribute 'test' not found}, "invalid attribute";


lives_ok { check_has( code => "SELECT 'dummy';" ); } "All OK";


done_testing();
