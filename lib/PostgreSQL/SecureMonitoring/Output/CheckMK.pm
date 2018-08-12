package PostgreSQL::SecureMonitoring::Output::CheckMK;

=encoding utf8

=head1 NAME 

  PostgreSQL::SecureMonitoring::Output::CheckMK -- check_mk-Output module for posemo
  
=head1 SYNOPSIS

   use PostgreSQL::SecureMonitoring::Run output => "JSON";
   
   my $posemo = PostgreSQL::SecureMonitoring::Run->new_with_options();
   $posemo->run;


=head1 DESCRIPTION

This Module generates output for the Check MK monitoring system in PiggybackHosts format. 
All hosts results are in one results file (or output).

This module generates everything completely ready for Check_MK.


=head2 IMPORTANT TODO!

 TODO: remove and clean up everything with local.
       clean up code and comments
       remove no critics


=head2 output 

The output is a text with the following elements:


At start:

   <<<posemo>>>
     $METADATA

$METADATA is basic metadata (everything in the first level except the C<result> key in the internal 
data structure or default JSON output) as JSON.


per Host one block with the following content:

  <<<<hostname>>>>
  <<<posemo>>>
     $JSON
  <<<<>>>

$JSON is everything per host (from the internal data structure of default JSON output) as JSON.

The following will be removed in a later version (the python part only uses the C<_check_mk key>)

 # For easyer parsing at Python/Check_MK side, the JSON contains some extra keys, ready for Check_MK:
 # 
 #   check_mk_inventory:  complete inventory
 #   check_mk_data:       complete results with perfdata and all values


This parts of the data strucre can be used to read out all results and pass them to the check_mk core. 

This is used by C<frontend_connectors/check_mk/posemo>. 




=head2 special values for check_mk in output


=head3 Precalculated check_mk perfdata

In the key C<_check_mk>, this output module has the complete result for check_mk,


=head2 metrics files

As of Posemo version 0.6.3, this output module can generate metrics files.

Unless you add your own checks, you don't need to generate new metrics files 
and can use the precreated in C<frontend_connectors/check_mk/metrics/posemo>.


  TODO: docs
  TODO: remove local; rewite partly.


=cut

use Moose::Role;
use Moose::Util::TypeConstraints;
use JSON;

use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf( "posemo-logging.properties", "Posemo" ) );

use English qw( -no_match_vars );

use IO::All -utf8;

requires qw(add_output loop_over_all_results);

=head2 Additional attributes

=over 4

=item * pretty

Flag (boolean), if the output should be formatted pretty or compact (default).

=item * metrics_outfile

An additional outfile for the check_mk metrics. Default: to STDOUT (C<->)

=item * service_type

The type for the metrics file B<and> check_mk output. Default: C<none>, which does 
not generate a metrics file and generates the same output as with C<local>.

Other values may be C<global> and C<local>: global creates a global metrics file, which 
[…] ((TODO!))

When you want C<local> check_mk output, then always also an metrics file will 
be generated.

=back

=cut

#<<<
has pretty          => ( is => "ro", isa => "Bool",                           default => 0, );
has metrics_outfile => ( is => "ro", isa => "Str", );
has service_type    => ( is => "ro", isa => enum( [qw(none global local )] ), default => "none", );
has _metric_info    => ( is => "ro", isa => "HashRef",                        default => sub { return {} } );
has _graph_info     => ( is => "ro", isa => "HashRef",                        default => sub { return {} } );
#>>>

has _metrics_output => (
                         accessor => "metrics_output",
                         traits   => ['String'],
                         is       => "rw",
                         isa      => "Str",
                         default  => q{},
                         handles  => {
                                      add_metrics => "append",
                                    },
                       );


my %color_mapping = (
                      default      => "35/a",
                      default_1    => "35/a",
                      default_2    => "45/a",
                      default_3    => "15/a",
                      default_4    => "25/a",
                      default_5    => "31/a",
                      default_6    => "41/a",
                      default_7    => "11/a",
                      default_8    => "21/a",
                      default_9    => "51/a",
                      green        => "35/a",
                      pastel_green => "31/a",
                      red          => "14/a",
                      yellow       => "22/a",
                      light_yellow => "24/a",
                      blue         => "45/a",
                      light_blue   => "42/a",
                      purple       => "11/a",
                      orange       => "21/a",
                      orange_red   => "16/a",
                    );

# build variants
$color_mapping{ $ARG . "_variant" }
   = substr( $color_mapping{$ARG}, 0, 3 ) . "b"    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
   foreach keys %color_mapping;



=head1 METHODS

=head2 generate_output

Implements the output mechanism, here check_mk PiggybackHosts format, 
which contains encapsulated JSON.


Finally it adds two keys to each host:

   check_mk_inventory   => [ 
                              [ "Service Name 1", undef ], 
                              [ "Service Name 2", undef ], 
                              # ... 
                           ]
   check_mk_data        => [ 
                              [ $status_code,  $infotext, [ [ $metric_name, $value, $warn, $crit, $min, $max ], (…)  ]  ], 
                              [ $status_code,  $infotext, [ [ $metric_name, $value, $warn, $crit, $min, $max ], (…)  ]  ], 
                              # ... 
                           ]
 
 
 

=cut


sub generate_output
   {
   my $self            = shift;
   my $complete_result = shift;

   my $json = JSON->new->pretty( $self->pretty );

   #
   # basic metadata
   #

   my %metadata;

   foreach my $key ( keys %$complete_result )
      {
      # ignore results
      next if $key eq "result";

      # next if ref $complete_result->{$key};

      $metadata{$key} = $complete_result->{$key};
      }

   $self->add_output( "<<<posemo_base>>>\n" . $json->encode( \%metadata ) . "\n" );



   # NEW version:
   # let main code loop over all hosts.
   # this calls the following methods:
   #   for_each_host
   #   for_each_check
   #   for_each_row_result
   #   for_each_single_result
   #

   $self->loop_over_all_results($complete_result);

   return unless $self->metrics_outfile;

   my $metric_info = $self->_metric_info;
   my $graph_info  = $self->_graph_info;

   my $now = localtime;

   $self->add_metrics(<<"FINISHED");
#
# Posemo metric_info and graph_info definitions
# Generated by Posemo $PostgreSQL::SecureMonitoring::VERSION ($now)
#
# DO NOT CHANGE MANUALLY!
#

#
# Part 1: metric_info definitions
#

FINISHED

   # format:
   # metric_info["writeable__write_time"] = {
   #     "title" : _("Write time"),
   #     "unit"  : "s",
   #     $color
   # }
   foreach my $metric_name ( sort keys %$metric_info )
      {

      # Get Color: lookup defined value; or "default_$pos";
      #            When nothing found via lookup (e.g. #123456), take the value directly
      my $color = $color_mapping{ $metric_info->{$metric_name}{color} // "default_$metric_info->{$metric_name}{_pos}" }
         // $metric_info->{$metric_name}{color};

      $self->add_metrics(<<"FINISHED");
metric_info["$metric_name"] = {
    "title" : _("$metric_info->{$metric_name}{title}"),
    "unit"  : "$metric_info->{$metric_name}{unit}",
    "color" : "$color",
}

FINISHED
      }


   #
   # graph_info["writeable"] = {
   #     "title"     : _("Writeable"),
   #     "metrics"   : [
   #         ( "writeable__write_time", "line" ),
   #         ...
   #     ]
   # }
   #

   $self->add_metrics(<<"FINISHED");

#
# Part 2: graph_info definitions
#

FINISHED

   foreach my $graph_name ( sort keys %$graph_info )
      {
      my $metrics_list = "";
      $metrics_list .= qq{        ("$ARG->[0]", "$ARG->[1]"),\n} foreach @{ $graph_info->{$graph_name}{metrics} };

      $self->add_metrics(<<"FINISHED");
graph_info.append({
    "title"     : _("$graph_info->{$graph_name}{title}"),
    "metrics"   : [
$metrics_list    ]
})
    
FINISHED
      }

   return;
   } ## end sub generate_output


=head2 for_each_host($host_result)

This method will be called by Posemo for each host (via ->loop_over_all_results).

It creates the JSON output and adds it to the complete output.

=cut


sub for_each_host
   {
   my $self        = shift;
   my $host_result = shift;

   # Reformat result and write it into check_mk_inventory and check_mk_data keys

   foreach my $service_name ( sort keys %{ $host_result->{_check_mk} } )
      {
      $host_result->{_check_mk}{$service_name}[1] =~ s{,\s$}{};    # remove trailing list delimeter
      push @{ $host_result->{check_mk_inventory} }, [ $service_name, undef ];
      push @{ $host_result->{check_mk_data} }, $host_result->{_check_mk}{$service_name};
      }

   # remove temporary values
   # delete $host_result->{_check_mk};

   my $json = JSON->new->pretty( $self->pretty );  # may be cached, but performance should be no problem here

   #<<< no pertidy formatting
   $self->add_output( "<<<<$host_result->{name}>>>>\n"
           .  "<<<posemo>>>\n"
           .  $json->encode( $host_result ) . "\n" );
   #>>>

   return;
   } ## end sub for_each_host


# =head2 for_each_check( $host_result, $check_result )
#
# This method will be called by Posemo for each check (via ->loop_over_all_results).
#
# It creates a service per check, except for multiline in global mode,
# then one service per row is created by C<for_each_row_result>
#
# =cut
#
# sub for_each_check
#    {
#    my $self         = shift;
#    my $host_result  = shift;
#    my $check_result = shift;
#
#    return if $check_result->{row_type} eq "multiline" and $self->metric_type ne "local";
#
#
#
#    return;
#    }


#
# =head2 for_each_row_result($host_result, $check_result, $row)
#
# This method will be called by Posemo for each single row
# for multiline results (via ->loop_over_all_results).
#
# When the result is not of type C<multiline>, this method will NOT be called.
#
# =cut
#
# sub for_each_row_result
#    {
#
#    }


=head2 for_each_single_result($host_result, $check_result, $single_result)

This method will be called by Posemo for each single result (via ->loop_over_all_results).

It builds the data structure for check_mk and metrics output.

   # check_mk single result (final row) name:
   # Global or none service_type:
   #     Metric-Name: check_name, column_name
   #     + Service name = Check-Name (+row title when multiline)
   # Local service_type:
   #     As above when NOT multiline; when multiline then:
   #       Metric-Name: check_name, row_title, column_name
   #       + Service Name = Check Name (only)
   #


Result is stored internally as hashref in the C<$host_result> in the key C<_check_mk> 
in the following format:

   _check_mk => 
      {
      "Service name 1" => [ $status_code,  $infotext, [ [ $metric_name, $value, $crit, $warn, $min, $max ], (…)  ]  ]
      "Service name 2" => [ $status_code,  $infotext, [ [ $metric_name, $value, $crit, $warn, $min, $max ], (…)  ]  ]
      }



=cut

#
# Unit-Mappings
# Map internal Posemo units to Check_MK units
#
# Key:   Posemo unit
# Value: reference to a sub;
#        parameter: value
#        return value: new value, Check_MK unit
#

use constant BUFSIZE => 8 * 1024;

#<<<
my %unit_mappings =
   (
   ms      => sub { return $ARG[0] / 1000,   "s"; },                    # check_mk doesn't know milliseconds
   buffers => sub { return $ARG[0] * BUFSIZE, "bytes"; },                # hmmm, check module should calculate correct bytes, because we don't know real buffer size!
   );
# Wrong mapping: 
# my %unit_mappings = 
#    (
#    q{%}    => sub { return "$ARG[0]%" },                                         # no space with %, see Check_MK guidelines
#    ms      => sub { return ( ( $ARG[0] / 1000 ) . " s" ) },                      # check_mk doesn't know milliseconds
#    buffers => sub { return ( ( $ARG[0] * 8*1024) . " bytes" )},                  # hmmm, check module should calculate correct bytes, because we don't know real buffer size!
#    );
#>>>


sub for_each_single_result                         ## no critic (Subroutines::ProhibitExcessComplexity)
   {                                               # this is a complex method, but linear ... (TODO: split in smaller subs?)
   my $self          = shift;
   my $host_result   = shift;
   my $check_result  = shift;
   my $single_result = shift;

   #
   # Build the service name / key
   #

   ( my $function_name = $check_result->{sql_function_name} ) =~ s{^(.*[.])}{}msx;   # Remove schema name from check_function_name
   ( my $column        = $single_result->{column} ) =~ s{\W}{_}g;                    # Remove all non-word-chars from column ...
   ( my $title         = $single_result->{title} // q{} ) =~ s{\W}{_}g;              # ... and title

   my $service_name = "PostgreSQL $check_result->{check_name}";
   my $graph_title  = $check_result->{description};
   my $graph_name   = "posemo__$function_name";
   my $metric_name;

   if ( $self->service_type eq "local" )
      {
      # do local type key building
      $metric_name
         = $title
         ? "${function_name}__${title}__$column"
         : "${function_name}__$column";
      $graph_name .= "__$title";
      $graph_title .= " of " . ( $single_result->{title} ) if $single_result->{title};
      }
   else
      {
      # global keys
      $metric_name = "posemo__${function_name}";
      $metric_name .= "__$column" if $check_result->{row_type} ne "single";

      if ( $single_result->{title} )
         {
         $service_name .= " of" if $single_result->{title} ne "!TOTAL";
         $service_name .= " $single_result->{title}";
         }
      }

   ( $graph_name = lc($graph_name) ) =~ s{\W}{_}g;


   my $value = my $msg_value = $single_result->{value};
   my $cmk_unit;

   if ( $check_result->{result_unit} and defined $value and $unit_mappings{ $check_result->{result_unit} } )
      {
      ( $value, $cmk_unit ) = &{ $unit_mappings{ $check_result->{result_unit} } }($value);
      }
   else
      {
      $cmk_unit = $check_result->{result_unit};
      }

   $cmk_unit = "count" if not $cmk_unit and $check_result->{result_is_counter};

   # build Perfdata
   my @this_perfdata = (
                         $metric_name, $value,
                         $check_result->{critical_level},
                         $check_result->{warning_level},
                         $check_result->{min_value},
                         $check_result->{max_value},
                       );

   # remove trailing undefs (Check_MK guidelines), but not the value (keep two)
   pop @this_perfdata while @this_perfdata > 2 and not defined $this_perfdata[-1];

   # Add perfdata to temporary internal storage
   push @{ $host_result->{_check_mk}{$service_name}[2] }, \@this_perfdata;

   # set status
   # thanks to autovivification, all elements in hash are generated on the fly
   $host_result->{_check_mk}{$service_name}[0] = $check_result->{status};

   # name of the column according Check_mk Guideline
   ( my $colname = ucfirst( $single_result->{column} ) ) =~ s{_}{ }g;

   # build infotext ...
   # TODO: when error, then usually there is no result, so the following case "error" can't happen???
   #       build an undef one in loop_over_all_results?
   my $msg = $check_result->{message} // $check_result->{error};
   if ($msg)                                       # take existing message or the results as text?
      {
      $host_result->{_check_mk}{$service_name}[1] = $check_result->{$msg};
      }
   elsif ( $self->service_type ne "local" or not $title or $title eq "_TOTAL" )    # Only add msg values for totals!
      {
      # unit with Check_MK guidelines: no space before %!
      my $unit = $check_result->{result_unit} // "";
      if ( defined $msg_value )
         {
         if    ( $unit eq q{%} ) { $msg_value .= q{%} }
         elsif ($unit)           { $msg_value .= " $unit" }
         }
      else
         {
         $msg_value = "(undefined value)";
         }

      $host_result->{_check_mk}{$service_name}[1] .= "$colname: $msg_value, ";
      }


   # return if $self->service_type eq "none";

   #
   # add metricts and graph info stuff.
   # When check_mk can not use this input from agent plugin, then do it global and create python file
   #

   #
   # metric_info["writeable__write_time"] = {
   #     "title" : _("Write time"),
   #     "unit"  : "s",
   #     $color
   # }
   #
   #

   my $metric_info = $self->_metric_info;
   my $graph_info  = $self->_graph_info;

   $metric_info->{$metric_name} = {
                                    title => $colname,                           # I18N missing, can't do python function call!
                                    unit  => $cmk_unit,
                                    _pos  => ( $single_result->{pos} // 0 ),
                                  };
   $metric_info->{$metric_name}{color} = $single_result->{color} if $single_result->{color};


   # graph_info["writeable"] = {
   #     "title"     : _("Writeable"),
   #     "metrics"   : [
   #         ( "writeable__write_time", "line" ),
   #         ...
   #     ]
   # }
   #

   $graph_info->{$graph_name}{title} = $graph_title;    # I18N missing, can't do python function call!

   # for non local multiline, build only the first row (!TOTAL)
   if ( not defined $single_result->{title} or $single_result->{title} eq '!TOTAL' or $self->service_type eq "local" )
      {
      # Graph type default with Posemo is LINE, except single result, then area!
      my $graph_type = $check_result->{graph_type} // ( $check_result->{row_type} eq "single" ? "area" : "line" );

      # convert "stacked_area" into "area" (first) or "stacked" (other)
      if ( $graph_type eq "stacked_area" )
         {
         if   ( $graph_info->{$graph_name}{metrics} ) { $graph_type = "stack"; }
         else                                         { $graph_type = "area"; }
         }

      # When mirrored: each second value is mirrored
      if (     $check_result->{graph_mirrored}
           and $graph_info->{$graph_name}{metrics}
           and @{ $graph_info->{$graph_name}{metrics} } % 2 == 1 )
         {
         $graph_type = "-$graph_type";
         }

      push @{ $graph_info->{$graph_name}{metrics} }, [ $metric_name, $graph_type ];
      } ## end if ( not defined $single_result...)

   return;
   } ## end sub for_each_single_result



=head2 after write_result

After C<write_result>, write our metrics result.

=cut

after write_result => sub {
   my $self = shift;
   return unless $self->metrics_outfile;

   io( $self->metrics_outfile )->print( $self->metrics_output );
   return;
};



1;
