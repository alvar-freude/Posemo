package Test::PostgreSQL::SecureMonitoring;

use strict;
use warnings;

=head1 NAME

 Test::PostgreSQL::SecureMonitoring - Test Class for PostgreSQL Secure Monitoring

 $Id: SecureMonitoring.pm 672 2017-04-26 22:58:00Z alvar $

=head1 VERSION

Version 0.1.0

=cut

use version; our $VERSION = qv("v0.1.0");


=head1 SYNOPSIS

  use Test::PostgreSQL::SecureMonitoring; 
  
  

=encoding utf8

  use Test::PostgreSQL::SecureMonitoring;
  
  my $result = result_ok($check);
  my $result = result_ok($check, $clustername);
  my $result = result_ok($check, $clustername, $message);
  
  warning($result, $message);                   # message always optional
  no_warning_ok($result, $message);
  critical_ok($result, $message);
  no_critical_ok($result, $message);
  
  name_is($result, $name, $message);
  
  result_is($result, 1, $message);              # you can check the reasult vakue with some builtin
  is($result->{result}, 1, $message);           # use Test::More!
  ok($result->{result} > 2, $message);          # you can check the resukt manually
  
  result_eq_or_diff($result, $data, $message);
  
  # more to be done when needed
  
  
  

=head1 DESCRIPTION


=cut

use parent 'Test::Builder::Module';



1;
