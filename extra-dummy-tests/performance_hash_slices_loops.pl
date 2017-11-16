#!/usr/bin/env perl

use strict;
use warnings;


use Benchmark qw(:hireswallclock timethese cmpthese);



my $conf = {
   'check' => {
      'Writeable' => {
                       'enabled' => 0
                     },
      OtherCHeck => {
                      critical => 100,
                      warning  => 50,
                    },
      MoreCheck => {
                     here => "are",
                     more => "parameters",
                     with => "this",
                     bla  => "fasel",
                   },
      Simple => {
         enabled => 0,

                },
              },
   'hostgroup' => {
                    'Elephant' => {
                                    'check' => {
                                                 'Writeable' => {
                                                                  'enabled' => 1,
                                                                  'timeout' => '100'
                                                                }
                                               },
                                    'hosts' => 'loc1_db1 loc1_db2 loc2_db1 loc2_db2',
                                    'order' => 10
                                  },
                    'Mammut' => {
                                  'order' => 20,
                                  'hosts' => [
                                               {
                                                 'port' => '5433',
                                                 'host' => 'loc1_db3'
                                               },
                                               {
                                                 'host' => 'loc1_db3',
                                                 'port' => '5434'
                                               }
                                             ]
                                },
                    'ApplicationTests' => {
                                            'enabled' => 0,
                                            'hosts'   => [
                                                         {
                                                           'host'   => 'db_lion',
                                                           'schema' => 'posemo_monitoring',
                                                           'check'  => {
                                                                        'ApplicationLion' => {
                                                                                               'enabled' => 1
                                                                                             }
                                                                      }
                                                         },
                                                         {
                                                           'schema' => 'posemo_monitoring',
                                                           'host'   => 'db_tiger',
                                                           'check'  => {
                                                                        'ApplicationTiger' => {
                                                                                                'critical_level' => '1000',
                                                                                                'enabled'        => 1
                                                                                              }
                                                                      }
                                                         }
                                                       ],
                                            'order' => 99999
                                          }
                  },
   'passwd'   => '',
   'schema'   => 'public',
   'database' => 'monitoring',
   'user'     => 'monitoring',
   'host'     => 'database.internal.project.tld',
   'port'     => '',
           };

my @host_parameter_names_predefined
   = qw(user passwd schema database port);

my $bench = timethese(
   -2,
   {
      hash_slices_var => sub {
         my %default;
         my @host_parameter_names
            = qw(user passwd schema database port);
         @default{@host_parameter_names} = @{$conf}{@host_parameter_names};
      },

      hash_slices_var_predefined => sub {
         my %default;
         @default{@host_parameter_names_predefined} = @{$conf}{@host_parameter_names_predefined};
      },

      hash_slices_qw => sub {
         my %default;
         @default{qw(user passwd schema database port)}
            = @{$conf}{qw(user passwd schema database port)};
      },

      foreach_loop => sub {
         my %default;
         foreach
            my $parameter (qw(user passwd schema database port))
            {
            $default{$parameter} = $conf->{$parameter};
            }
      },

      map_functional => sub {
         my %default = map { $_ => $conf->{$_} }
            qw(user passwd schema database port);
      },

   }
);


#my %default;
#my $bench = timethese(
#   -2,
#   {
#
#      hash_slice => sub {
#         my %default;
#         $default{_check_params}{ keys %{ $conf->{check} } } = @{ $conf->{check} }{ keys %{ $conf->{check} } };
#      },
#
#      foreach_loop => sub {
#         my %default;
#         foreach my $check_name ( keys %{ $conf->{check} } )    # tmp comment
#            {
#            $default{_check_params}{$check_name} = $conf->{check}{$check_name};
#            }
#      },
#
#   }
#);
#
#
#cmpthese $bench;


#
#my %default;
#my @host_parameter_names = qw(user passwd schema database port);
#@default{@host_parameter_names} = @{$conf}{@host_parameter_names};
#$default{_check_params}{ keys @{ $conf->{check} } } = @{ $conf->{check} }{ keys @{ $conf->{check} } };
#
#
#foreach my $check_name ( keys @{ $conf->{check} } )    # tmp comment
#   {
#   $default{_check_params}{$check_name} = $conf->{check}{$check_name};
#   }
#
#

