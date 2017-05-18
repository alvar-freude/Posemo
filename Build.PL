#
# $Id: Build.PL 669 2016-11-24 16:19:30Z alvar $
#


#
# TODO:
# testcover geht nicht
# Workaround:
#   HARNESS_PERL_SWITCHES=-MDevel::Cover TEST_AUTHOR=1 prove t/
#   cover
#

use 5.014;
use strict;
use warnings FATAL => 'all';
eval { use Module::Build; return 1; } or die "Please install Module::Build for installation\n";

#                                                 dbname_init   => $ENV{POSEMO_DATABASE_INIT} // 'postgres',
#                                                 username_init => $ENV{POSEMO_USER_INIT},
my $builder = Module::Build->new(
   module_name       => 'Posemo',
   license           => 'artistic_2',
   dist_author       => q{Alvar C.H. Freude <alvar@a-blast.org>},
   dist_version_from => 'lib/PostgreSQL/SecureMonitoring.pm',
   dist_abstract     => 'PostgreSQL Secure Monitoring -- flexible and secure Postgres monitoring',
   test_file_exts    => [qw(.t .pg)],
   release_status    => 'testing',

   tap_harness_args => {
                         sources => {
                                      Perl  => undef,
                                      pgTAP => {
                                                 dbname    => '_posemo_tests',
                                                 username  => '_posemo_superuser', # pgTAP needs superuser!
                                                 # superuser => '_posemo_superuser',
                                                 host      => undef,
                                                 suffix    => '.pg',
                                                 port      => 15432,
                                               },
                                    },
                       },
   
   configure_requires => { 'Module::Build' => 0, },
   build_requires     => {
      'Test::More'                        => 0,
      'Test::Exception'                   => 0.25,
      'TAP::Parser::SourceHandler::pgTAP' => 3.25,

      # 'Test::MockObject'     => 1.20140408,
      # 'Test::File'           => 1.41,
                     },

   # TODO:
   # Check minimal required versions!
   # this versions are set to my installed versions at writing time ...
   # usually it should work with older versions of this modules, but this
   # is not tested.
   requires => {
      'DBI'                    => 1.633,
      'DBD::Pg'                => '3.5.1',
      'Moose'                  => 2.0401,
      'MooseX::Getopt'         => 0.37,
      'MooseX::ConfigFromFile' => 0.04,
      'Log::Log4perl'          => 1.29,
      'Config::General'        => 2.50,
      'Readonly'               => 1.03,
      'IO::All'                => 0.84,

      # not available in ubuntu 12.04 LTS, shipped in extlib:
      # 'MooseX::SimpleConfig'   => 0.10,
               },
   add_to_cleanup     => ['Posemo-*'],
   create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();


