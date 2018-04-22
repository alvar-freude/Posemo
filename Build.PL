#
# Build-File
# This file describes all Build-Time-Depencencies, test configuration etc.
#
# run as:
#   perl ./Build.PL
#


use 5.014;
use strict;
use warnings FATAL => 'all';
eval " use Module::Build; return 1; " or die "Please install perl module Module::Build for installation. Stopped.\n";

# The socketdir, which is used by Test::PostgreSQL::Starter
my $socketdir = ( $ENV{POSTGRES_TEST_DIR} // "/tmp/_test-postgresql-starter" ) . "/sockets";

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
                    dbname   => '_posemo_tests',
                    username => '_posemo_tests',           # no superuser -- switch manuelly, when pgTAP needs it!
                                                           # superuser => '_posemo_superuser',
                    host     => $socketdir,
                    suffix   => '.pg',
                    port     => 15432,
                  },
                 },
   },

   configure_requires => { 'Module::Build' => 0, },
   build_requires     => {
      'Test::More'                        => 0,
      'Test::Exception'                   => 0.25,
      'TAP::Parser::SourceHandler::pgTAP' => 3.25,
      'Test::Differences'                 => 0.64,
      'Config::Tiny'                      => 2.20,

      # 'Test::MockObject'     => 1.20140408,
      # 'Test::File'           => 1.41,
                     },

   # TODO:
   # Check minimal required versions!
   # this versions are set to my installed versions at writing time ...
   # usually it should work with older versions of this modules, but this
   # is not tested.
   requires => {
      'DBI'                       => 1.631,
      'DBD::Pg'                   => '3.5.1',
      'Moose'                     => 2.0401,
      'MooseX::Getopt'            => 0.37,
      'MooseX::Types::Path::Tiny' => 0.011,        # missing(??) dependency in MooseX::ConfigFromFile
      'MooseX::SimpleConfig'      => 0.11,
      'MooseX::ConfigFromFile'    => 0.04,
      'Log::Log4perl'             => 1.29,
      'Config::General'           => 2.50,
      'Readonly'                  => 1.03,
      'IO::All'                   => 0.84,
      'File::HomeDir'             => 1.00,         # used by Config::FindFile
      'File::ShareDir'            => 1.102,        # used by Config::FindFile
      'JSON'                      => 2.90,

      # currently not used:
      # 'Config::Validate'  => '0.2.6',
      # ' Data::Validate '  => 0.09, ???

               },

   # install default configs (e.g. logging.properties!) in share_dir
   share_dir => {
      module => {
                  'PostgreSQL::SecureMonitoring' => [ 'conf', ],
                },

   },

   add_to_cleanup     => [' Posemo-*'],
   create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();


=begin install Ubuntu dependencies

  # UNTESTED!
  apt-get install libdbd-pg-perl \
      libmoosex-simpleconfig-perl \
      libmoosex-configfromfile-perl \
      liblog-log4perl-perl \
      libconfig-general-perl \
      libreadonly-perl \
      libio-all-perl \
      libfile-homedir-perl \
      libfile-sharedir-perl \
      libconfig-tiny-perl \
      libjson-perl \
      libjson-xs-perl \
      libmodule-build-perl

  # Test Dependencies:
  apt-get install libtap-parser-sourcehandler-pgtap-perl libtest-differences-perl libtest-exception-perl libtext-diff-perl


=end

=cut

