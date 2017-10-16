#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;


BEGIN { use_ok( "Config::FindFile", "search_conf" ); }

use Config::FindFile qw(search_conf);


throws_ok { search_conf("neverfound.conf"); } qr{UUUPS, FATAL: configfile neverfound[.]conf not found},
   "Config not found exception";

lives_ok { search_conf("logging.properties"); } "found logging propertiees";


# TODO:
# Test the other conditions!
# Not simple, because chroot only possible as root user.


done_testing();

