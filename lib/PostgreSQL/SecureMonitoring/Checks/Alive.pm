package PostgreSQL::SecureMonitoring::Checks::Alive;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Alive -- minimalistic alive check

=head1 SYNOPSIS

...

=head1 DESCRIPTION

This is a minimalistic Posemo check. It creates a SQL for a simple function, 
which just returns true. So, if the server is alive, then it returns true.

=head2 TODO

Catch DBI connection error and return 0 (not alive) instead of error!

=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has
   description => 'Checks if server is alive.',
   code        => "SELECT true";

1;


