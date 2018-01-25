#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use PostgreSQL::SecureMonitoring::Install;

PostgreSQL::SecureMonitoring::Install->new_with_options->install;



