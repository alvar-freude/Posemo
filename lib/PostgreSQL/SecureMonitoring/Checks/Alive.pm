package PostgreSQL::SecureMonitoring::Checks::Alive;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::Alive -- minimalistic alive check

=head1 SYNOPSIS

...

=head1 DESCRIPTION

This is a minimalistic Posemo check. It creates a SQL for a simple function, 
which just returns true. So, if the server is alive, then it returns true.


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has code => "SELECT true";

1;


