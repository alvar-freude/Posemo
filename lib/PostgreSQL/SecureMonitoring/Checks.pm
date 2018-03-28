package PostgreSQL::SecureMonitoring::Checks;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks -- base class for all Posemo checks

=head1 SYNOPSIS


 package PostgreSQL::SecureMonitoring::Checks::Alive;  # by Default, the name of the check is build from this package name
 
 use Moose;                                            # This is a Moose class ...
 extends "PostgreSQL::SecureMonitoring::Checks";       # ... which extends our base check class
 
 sub _build_sql { return "SELECT true;"; }             # this sub simply returns the SQL for the check
 
 1;                                                    # every Perl module must return (end with) a true value


=head1 DESCRIPTION

This is the base class for all Posemo checks. It declares all base methods for 
creating SQL in initialisation, calling the check at runtime etc.

The above minimalistic example MyCheck creates the following SQL function:

  CREATE OR REPLACE FUNCTION my_check() 
    RETURNS  boolean 
    AS
    
    $code$
      SELECT true;
    $code$
    
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = monitoring, pg_temp;
  
  ALTER FUNCTION my_check OWNER TO postgres;
  REVOKE ALL     ON FUNCTION my_check() FROM PUBLIC;
  GRANT  EXECUTE ON FUNCTION my_check() TO monitoring;
  

At runtime it is called with this SQL:

  SELECT * FROM my_check();
  


=head2 results


There may be a lot of different ways for check modules to deliver their results.

There may be one result, e.g. true/false or a single number (e.g. number of backends), 
or multiple values for e.g. multiple databases



If there are more then one database which delivers inforations in one check, it 
should report the database in the first column:


   database   | total | active | idle | idle in transaction | idle aborted | fastpath  | disabled
  ------------+-------+--------+------+---------------------+-------
   $TOTAL     |   137 |     18 |  111 |                   8 |     0
   postgres   |     1 |      0 |    1 |                   0 |     0
   monitoring |     1 |      1 |    0 |                   0 |     0
   test_1     |   123 |     16 |  100 |                   7 |     0
   test_2     |    12 |      1 |   10 |                   1 |     0



Types of results:

 * Single value: scalar

 * Multiple single values: Array of scalars

 * Multiple rows with multiple values: array of arrayrefs

Structure for output/result:

   [
      {
      host => "hostname",
      results => 
         [
            {
            check       => "check_name",
            result      => [ {}, {}, ... ],
            result_type => "",   # multiline, single, list
            columns     => [qw(database total active idle), "idle in transaction", "other", ],
            critical    => 0,    # or 1
            warning     => 0,    # or 1
            message     => "",   # warn/crit message or empty
            error       => "",   # error message, e.g. when can't run the check
            },
         ],
      },
     
   ]



Simple results: one value.


More complex: 








This check would give 5 results; ouput modules should use the databse in the check name and 
each value in the performance data



=head2 TODO

TODO: SQL schema handling; 
should be: default empty and user should have an search_path? (to "monitorin")???



=cut


use Moose;
use namespace::autoclean;

use Scalar::Util qw(looks_like_number);
use List::Util qw(any);
use English qw( -no_match_vars );
use Data::Dumper;

use Config::FindFile qw(search_conf);
use Log::Log4perl::EasyCatch ( log_config => search_conf("posemo-logging.properties") );

=begin temp

Folgende Methoden:

  * sql
  * sql_function
  * sql_function_name
  * return_type (boolean)
  * language (sql)
  * name
  * 
  * 
  
von app/basis
  * schema
  * superuser
  * user
  * ...


Wir brauchen: 

  Funktion "is_critical"
  Funktion "is_warning"
  Funktion "is_ok"

Wie Speichern Result?

#diag $dbh->{pg_server_version}  ;
#diag $dbh->{pg_server_version};


=end temp



=cut

#<<< no pertidy formatting

# lazy / build functions


foreach my $attr (qw(class name description code install_sql sql_function sql_function_name result_type order))
   {
   my $builder = "_build_$attr";
   has $attr => ( is => "rw", isa => "Str", lazy => 1, builder => $builder, );
   }

has return_type          => ( is => "ro", isa => "Str",           default   => "boolean", );
has result_unit          => ( is => "ro", isa => "Str",           default   => "", );
has language             => ( is => "ro", isa => "Str",           default   => "sql", );
has volatility           => ( is => "ro", isa => "Str",           default   => "STABLE", );
has has_multiline_result => ( is => "ro", isa => "Bool",          default   => 0, );
has result_is_counter    => ( is => "ro", isa => "Bool",          default   => 0, );
has has_writes           => ( is => "ro", isa => "Bool",          default   => 0, );
has parameters           => ( is => "ro", isa => "ArrayRef[Any]", default   => sub { [] }, traits  => ['Array'], 
                                                                                           handles => 
                                                                                             { 
                                                                                             has_parameters => 'count', 
                                                                                             all_parameters => 'elements', 
                                                                                             }, );

# The following values can be set via config file etc as parameter
has enabled              => ( is => "ro", isa => "Bool",          default   => 1,); 
has warning_level        => ( is => "ro", isa => "Num",           predicate => "has_warning_level", );
has critical_level       => ( is => "ro", isa => "Num",           predicate => "has_critical_level", );
has min_value            => ( is => "ro", isa => "Num",           predicate => "has_min_value", );
has max_value            => ( is => "ro", isa => "Num",           predicate => "has_max_value", );

# Internal states
has app                  => ( is => "ro", isa => "Object",        required  => 1,          handles => [qw(dbh has_dbh schema user superuser host port host_desc has_host has_port commit rollback)], );
# has result               => ( is => "ro", isa => "ArrayRef[Any]", default   => sub { [] }, ); 

# attributes for attrs with builder method
# the builder looks first here and when nothing found then uses his default
has _code_attr           => ( is => "ro", isa => "Str",           predicate => "has_code_attr", );
has _name_attr           => ( is => "ro", isa => "Str",           predicate => "has_name_attr", );
has _description_attr    => ( is => "ro", isa => "Str",           predicate => "has_description_attr", );
has _result_type_attr    => ( is => "ro", isa => "Str",           predicate => "has_result_type_attr", );


# Parameters, which may be set from check, or should be set here.
#has result_is_warning    => ( is => "rw", isa => "Bool",          default   => 0, );
#has result_is_critical   => ( is => "rw", isa => "Bool",          default   => 0, );



#>>>


#
# internal default builder methods
# for the default values of the attributes with builder
#

sub _build_class
   {
   my $self = shift;
   return $self unless ref $self;
   return blessed($self);
   }

sub _build_name
   {
   my $self = shift;

   return $self->_name_attr if $self->has_name_attr;

   my $package = __PACKAGE__;
   ( my $name = $self->class ) =~ s{ $package :: }{}ox;

   return _camel_case_to_words($name);
   }

sub _build_description
   {
   my $self = shift;
   return $self->_description_attr if $self->has_description_attr;
   return "The ${ \$self->name } check has no description";
   }

sub _camel_case_to_words
   {
   my $name = shift;
   die "Non-word characters in check name $name\n"                     if $name =~ m{[\W_]}x;
   die "Check package name must start with uppercase letter ($name)\n" if $name =~ m{ ^ [^[:upper:]] }x;

   $name =~ s{ ( [[:lower:][:digit:]]+ ) ( [[:upper:]]+ ) }
             {$1 $2}gx;

   $name =~ s{ ( [[:alpha:]]+ ) ( [[:digit:]]+ ) }
             {$1 $2}gx;

   return $name;
   }

sub _build_sql_function_name
   {
   my $self = shift;
   ( my $function_name = $self->name ) =~ s{\s}{_}gx;
   return lc("${ \$self->schema }.$function_name");
   }

sub _build_code
   {
   my $self = shift;
   return $self->_code_attr if $self->has_code_attr;
   die "The check (${ \$self->class }) must set his Code (or SQL-Function)\n";
   }

sub _build_install_sql
   {
   return "";
   }

sub _build_sql_function
   {
   my $self = shift;

   my ( @parameters, @parameters_with_default );
   foreach my $par_ref ( $self->all_parameters )
      {
      my $param              = "$par_ref->[0] $par_ref->[1]";
      my $param_with_default = $param;
      if ( defined $par_ref->[2] )
         {
         my $default = $par_ref->[2];

         #         $default = qq{'$default'} unless looks_like_number($default);
         $default = $self->dbh->quote($default) unless looks_like_number($default);
         $param_with_default .= " DEFAULT $default";
         }
      push @parameters,              $param;
      push @parameters_with_default, $param_with_default;
      }

   my $parameters              = join( ", ", @parameters );
   my $parameters_with_default = join( ", ", @parameters_with_default );

   my $setof = "";
   $setof = "SETOF" if $self->has_multiline_result;

   # When return type contains a space, then we need a new type!
   # because then the return type contains a list of elements
   my $return_type = $self->return_type;
   my $new_type    = "";

   if ( $return_type =~ m{\s} )
      {
      $new_type    = "CREATE TYPE ${ \$self->sql_function_name }_type AS ($return_type);";
      $return_type = "${ \$self->sql_function_name }_type";
      }

   return qq{$new_type
  CREATE OR REPLACE FUNCTION ${ \$self->sql_function_name }($parameters_with_default)
    RETURNS $setof $return_type
    AS   
    \$code\$
      ${ \$self->code }
    \$code\$
    LANGUAGE ${ \$self->language }
    ${ \$self->volatility }
    SECURITY DEFINER
    SET search_path = ${ \$self->schema }, pg_temp;
  
  ALTER FUNCTION             ${ \$self->sql_function_name }($parameters) OWNER TO ${ \$self->superuser };
  REVOKE ALL     ON FUNCTION ${ \$self->sql_function_name }($parameters) FROM PUBLIC;
  GRANT  EXECUTE ON FUNCTION ${ \$self->sql_function_name }($parameters) TO ${ \$self->user };
 };

   } ## end sub _build_sql_function

sub _build_result_type
   {
   my $self = shift;

   return $self->_result_type_attr if $self->has_result_type_attr;
   return $self->return_type;                      # result type is by default the same as the return type of the SQL function
   }

sub _build_order
   {
   return shift->name;
   }


=head1 METHODS


=head2 install

This method installs the check on the server.

Executes the SQL from sql_function on the server. 

This method does not commit!

No local error handling, don't disable RaiseError!

Only for installation use, needs an DB connection with 
superuser privileges


=cut

sub install
   {
   my $self = shift;

   if ( $self->install_sql )
      {
      TRACE "${ \$self->sql_function_name }: call extra SQL for installation " . $self->install_sql;
      $self->dbh->do( $self->install_sql );
      }

   TRACE "SQL-Function to install: " . $self->sql_function;
   $self->dbh->do( $self->sql_function );
   return $self;
   }

=head2 ->run_check()

Executes the check, takes the result, checks for critical/warning and returns the result...

Disabled checks are NOT skipped, this is the job of the caller!

=cut

sub run_check
   {
   my $self = shift;

   INFO "Run check ${ \$self->name } for host ${ \$self->host_desc }";

   # my $result = $self->enabled ? $self->execute : {};
   my $result = eval { return $self->execute; };

   unless ($result)
      {
      $result->{error} = "Error executing SQL function ${ \$self->sql_function_name } from ${ \$self->class }: $EVAL_ERROR\n";
      ERROR $result->{error};
      eval { $self->rollback if $self->has_dbh; return 1; } or ERROR "Error in rollback: $EVAL_ERROR";
      }

   $result->{check_name}        = $self->name;
   $result->{description}       = $self->description;
   $result->{result_unit}       = $self->result_unit;
   $result->{result_type}       = $self->result_type;
   $result->{result_is_counter} = $self->result_is_counter;

   foreach my $attr (qw(warning_level critical_level min_value max_value))
      {
      my $method = "has_$attr";
      next unless $self->$method;
      $result->{$attr} = $self->$attr;
      }

   # skip critical/warning test, when no real result!
   $self->test_critical_warning($result) if $self->enabled and not $result->{error};

   TRACE "Finished check ${ \$self->name } for host ${ \$self->host_desc }";
   TRACE "Result: " . Dumper($result);

   return $result;
   } ## end sub run_check

=head2 execute

Executes the check inside the PostgreSQL server and returns the result.

Throws exception on error!

=cut

sub execute
   {
   my $self = shift;

   my ( @values, @placeholders );

   foreach my $par_ref ( $self->all_parameters )
      {
      my ( $name, $type, $default ) = @$par_ref;
      push @values, $self->$name // $default;
      push @placeholders, q{?};
      }

   my %result;

   my $placeholders = join( ", ", @placeholders );

   # SELECT with FROM, because function with multiple OUT parameters will result in multiple columns
   TRACE "Prepare: SELECT * FROM ${ \$self->sql_function_name }($placeholders);";
   my $sth = $self->dbh->prepare("SELECT * FROM ${ \$self->sql_function_name }($placeholders);");
   DEBUG "All values for execute: " . join( ", ", map { "'$_'" } @values );
   $sth->execute(@values);

   $result{columns} = $sth->{NAME};

   if ( $self->has_multiline_result )
      {
      $result{result}   = $sth->fetchall_arrayref;
      $result{row_type} = "multiline";
      }
   else
      {
      my @row = $sth->fetchrow_array;

      if ( scalar @row <= 1 )
         {
         $result{result}   = $row[0];
         $result{row_type} = "single";
         }
      else
         {
         $result{result}   = \@row;
         $result{row_type} = "list";
         }
      }

   $sth->finish;

   $self->commit if $self->has_writes;

   return \%result;
   } ## end sub execute


=head2 test_critical_warning

This method checks, if the result is critical or warning.

It may be overriden in the check to do more detailed checks.

Default check depends on C<result_type> value of the result:

=over 4

=item single

Checks the single value against C<warning_level> / C<critical_level> attribute.

=item list

Checks every value against C<warning_level> / C<critical_level> attribute.

=item multiline

Checks checks every value except the first element of each row against C<warning_level> / C<critical_level> attribute

=back


=cut


sub test_critical_warning
   {
   my $self   = shift;
   my $result = shift;

   if ( $result->{row_type} eq "single" and $self->return_type eq "boolean" )
      {
      return if $result->{result};
      $result->{message}  = "Failed ${ \$self->name } for host ${ \$self->host_desc }";
      $result->{critical} = 1;
      return;
      }


   return unless $self->has_critical_level or $self->has_warning_level;

   my @values;

   $result->{return_type} = $self->return_type;

   if ( $result->{row_type} eq "single" )
      {
      @values = ( $result->{result} );
      }
   elsif ( $result->{row_type} eq "list" )
      {
      @values = @{ $result->{result} };
      }
   elsif ( $result->{row_type} eq "multiline" )
      {
      @values = map { splice( @$_, 1 ) } @{ $result->{result} };
      }
   else { $result->{error} = "FATAL: Wrong row_type '${ \$self->result_type }' in critical/warning-check\n"; }

   my $message = "";

   my ( @crit, @warn );
   @crit = grep { $_ >= $self->critical_level } @values if $self->has_critical_level;
   @warn = grep { $_ >= $self->warning_level } @values  if $self->has_warning_level;

   if (@crit)
      {
      $message = "Critical values: @crit! ";
      $result->{critical} = 1;
      INFO "$message in check ${ \$self->name } for host ${ \$self->host_desc }";
      }

   if (@warn)
      {
      $message .= "; " if $message;
      $message .= "Warning values: @warn! ";
      $result->{warning} = 1;
      INFO "Warning values: @warn in check ${ \$self->name } for host ${ \$self->host_desc }";
      }

   $result->{message} = $message if $message;

   return;
   } ## end sub test_critical_warning



=head2 enabled_on_this_platform

B<Usually you should not use this flag.>

Flag, if the check is globally enabled on the current platform. 

May be overridden in check, to disable some checks on some 
platforms or based on other (non config!) state. When the decision 
is about the configuration or something similar, the attribute 
"enabled" should used/overridden.

When a check module sets C<enabled_on_this_platform> to false, then 
the check will not run, because C<get_all_checks_ordered> removes it.

This should only be dependent on the platform, the application is 
running (local), not the PostgreSQL server (remote). 


=cut

sub enabled_on_this_platform
   {
   return 1;
   }



__PACKAGE__->meta->make_immutable;

1;

