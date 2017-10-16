#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;


BEGIN { use_ok( "Config::FindFile", "search_conf" ); }

use Config::FindFile qw(search_conf);


throws_ok { search_conf("neverfound.conf"); } qr{UUUPS, FATAL: configfile neverfound[.]conf not found}, "Config not found exception";


done_testing();


#PostgreSQL::SecureMonitoring
