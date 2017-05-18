package MooseX::SimpleConfig;
# git description: v0.10-12-gf8c77cf
$MooseX::SimpleConfig::VERSION = '0.11';
# ABSTRACT: A Moose role for setting attributes from a simple configuration file
# KEYWORDS: moose extension command line options attributes configuration file

use Moose::Role;
with 'MooseX::ConfigFromFile';

use Config::Any 0.13 ();

sub get_config_from_file {
    my ($class, $file) = @_;

    $file = $file->() if ref $file eq 'CODE';
    my $files_ref = ref $file eq 'ARRAY' ? $file : [$file];

    my $can_config_any_args = $class->can('config_any_args');
    my $extra_args = $can_config_any_args ?
        $can_config_any_args->($class, $file) : {};
    ;
    my $raw_cfany = Config::Any->load_files({
        %$extra_args,
        use_ext         => 1,
        files           => $files_ref,
        flatten_to_hash => 1,
    } );

    my %raw_config;
    foreach my $file_tested ( reverse @{$files_ref} ) {
        if ( ! exists $raw_cfany->{$file_tested} ) {
            warn qq{Specified configfile '$file_tested' does not exist, } .
                qq{is empty, or is not readable\n};
                next;
        }

        my $cfany_hash = $raw_cfany->{$file_tested};
        die "configfile must represent a hash structure in file: $file_tested"
            unless $cfany_hash && ref $cfany_hash && ref $cfany_hash eq 'HASH';

        %raw_config = ( %raw_config, %{$cfany_hash} );
    }

    \%raw_config;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SimpleConfig - A Moose role for setting attributes from a simple configuration file

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  ## A YAML configfile named /etc/my_app.yaml:
  foo: bar
  baz: 123

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::SimpleConfig';

  has 'foo' => (is => 'ro', isa => 'Str', required => 1);
  has 'baz'  => (is => 'rw', isa => 'Int', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_config(configfile => '/etc/my_app.yaml');
  # ... rest of the script here

  ####################
  ###### combined with MooseX::Getopt:

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::SimpleConfig';
  with 'MooseX::Getopt';

  has 'foo' => (is => 'ro', isa => 'Str', required => 1);
  has 'baz'  => (is => 'rw', isa => 'Int', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_options();
  # ... rest of the script here

  ## on the command line
  % perl my_app_script.pl -configfile /etc/my_app.yaml -otherthing 123

=head1 DESCRIPTION

This role loads simple files to set object attributes.  It
is based on the abstract role L<MooseX::ConfigFromFile>, and uses
L<Config::Any> to load your configuration file.  L<Config::Any> will in
turn support any of a variety of different config formats, detected
by the file extension.  See L<Config::Any> for more details about
supported formats.

To pass additional arguments to L<Config::Any> you must provide a
C<config_any_args()> method, for example:

  sub config_any_args {
    return {
      driver_args => { General => { '-InterPolateVars' => 1 } }
    };
  }

Like all L<MooseX::ConfigFromFile> -derived file loaders, this
module is automatically supported by the L<MooseX::Getopt> role as
well, which allows specifying C<-configfile> on the command line.

=head1 ATTRIBUTES

=for stopwords configfile

=head2 configfile

Provided by the base role L<MooseX::ConfigFromFile>.  You can
provide a default configuration file pathname like so:

  has '+configfile' => ( default => '/etc/myapp.yaml' );

You can pass an array of filenames if you want, but as usual the array
has to be wrapped in a sub ref.

  has '+configfile' => ( default => sub { [ '/etc/myapp.yaml', '/etc/myapp_local.yml' ] } );

Config files are trivially merged at the top level, with the right-hand files taking precedence.

=head1 CLASS METHODS

=head2 new_with_config

Provided by the base role L<MooseX::ConfigFromFile>.  Acts just like
regular C<new()>, but also accepts an argument C<configfile> to specify
the file from which to load other attributes.  Explicit arguments
to C<new_with_config> will override anything loaded from the file.

=head2 get_config_from_file

Called internally by either C<new_with_config> or L<MooseX::Getopt>'s
C<new_with_options>.  Invokes L<Config::Any> to parse C<configfile>.

=head1 AUTHOR

Brandon L. Black <blblack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Brandon L. Black <blblack@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Tomas Doran Brandon L Black Alexander Hartmaier lestrrat Ð¡ÐµÑ€Ð³ÐµÐ¹ Ð Ð¾Ð¼Ð°Ð½Ð¾Ð² Yuval Kogman Zbigniew Lukasiak Alex Howarth

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Brandon L Black <blblack@gmail.com>

=item *

Alexander Hartmaier <alex.hartmaier@gmail.com>

=item *

lestrrat <lestrrat+github@gmail.com>

=item *

Ð¡ÐµÑ€Ð³ÐµÐ¹ Ð Ð¾Ð¼Ð°Ð½Ð¾Ð² <sromanov@cpan.org>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Zbigniew Lukasiak <zby@cpan.org>

=item *

Alex Howarth <alex.howarth@gmail.com>

=back

=cut
