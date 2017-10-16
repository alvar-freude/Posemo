package Config::FindFile;

use Moose;
use 5.010;


=head1 NAME

Config::FindFile -  


=head1 VERSION

Version 1.0.20


=cut

use version; our $VERSION = qv("1.0.0");


=head1 SYNOPSIS

=encoding utf8

 use Config::FindFile qw(search_conf);
 
 my $app_config_file = search_conf("myapp.conf");
 my $log_config_file = search_conf("myapp-log.conf");


=head1 DESCRIPTION

This little helper module exports one sub C<search_conf>, which helps to finds a 
named config in some typical paths for config files.


=head2 search_conf( $file_name [, $module_name] )

Parameter: 

C<$file_name:> config file name without path.

C<$module_name:> Module name for searching via L<File::ShareDir|File::ShareDir>

TODO:
Take module name from caller, when not given.


C<search_conf> returns the first matching file in the search list below.

It dies, when no suitable (config) file is found.

=over 4

=item 1. 

For development etc: Relative to the executable direktory: C<$Bin/../conf>

=item 2.

In users home dir, with additional dot at beginning.

=item 3.

C</usr/local/etc>

=item 4.

C</etc>


=item 5. 

Modules ShareDir (e.g. for a pre-packaged default config file)


=back 4


=cut

use English qw( -no_match_vars );
use FindBin qw($Bin);
use File::HomeDir;
use File::ShareDir;

use base qw(Exporter);
our @EXPORT_OK = qw(search_conf);

use 5.010;                                         # "defined or" operator exists since perl 5.10!


sub search_conf
   {
   my $name = shift;
   my $module = shift // caller;

   # 1. Look on development place
   my $file = "$Bin/../conf/$name";
   return $file if -f $file;

   # 2. look in users home dir
   $file = File::HomeDir->my_home() . "/.$name";
   return $file if -f $file;

   # 3. /usr/local/etc
   $file = "/usr/local/etc/$name";
   return $file if -f $file;

   # 4. /etc
   $file = "/etc/$name";
   return $file if -f $file;

   # and othervise look in applications share dir
   my $distconfdir = eval { return File::ShareDir::module_dir($module) } // "conf";

   # warn "Share-Dir-Eval-Error: $EVAL_ERROR" if $EVAL_ERROR;
   $file = "$distconfdir/$name";
   return $file if -f $file;

   die "UUUPS, FATAL: configfile $name not found. Last try was <$file>.";

   # return;

   } ## end sub search_conf


1;
