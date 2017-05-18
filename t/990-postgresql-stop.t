#!/usr/bin/env perl

use strict;
use warnings;
use Test::PostgreSQL::Starter;
use Test::More;

pg_stop_ok("test");
pg_dropcluster_ok("test");



done_testing();


 