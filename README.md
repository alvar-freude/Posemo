See branch *dev* for Code.

# Posemo – PostgreSQL Secure Monitoring

Posemo is a PostgreSQL monitoring framework, that can monitor everything in Postgres with an unprivileged user. Posemo conforms to the rules of the *German Federal Office for Information Security* ([Bundesamt für Sicherheit in der Informationstechnik](https://www.bsi.bund.de/DE/Home/home_node.html), BSI).

Posemo itself has no display capabilities, but can output the results for every monitoring environment (e.g. check_mk, Nagios, Zabbix, Icinga, …).

…

## This is a Pre-Release, for Developers only!

More documentation will come. Posemo is in development an not yet usable!
**See *dev* branch for the code!**

Some parts of the documentation are missing.

And be aware: THERE WILL BE DRAGONS!


## Concepts

Posemo is a modular framework for creating Monitoring Checks for PostgreSQL. It is simple to add a new check. Usually just have to write the SQL for the check and add some configuration.

Posemo is a modern Perl application using Moose; at installation it generates PostgerSQL functions for every check. These functions are called by an unprivileged user who can only call there functions, nothing else. But since they are `SECURITY DEFINER` functions, they run with more privileges (usually as superuser). You need a superuser for installation, but checks can run (from remote or local) by an unprivileged user. Therefore, **the monitoring server has no access to your databases, no access to PostgreSQL internals – it can only call some predefined functions.**


For a simple check you may look below at the *Alive* Check, which simply returns true if the server is reachable. It uses a lot of defaults from `PostgreSQL::SecureMonitoring::Checks`:

```
package PostgreSQL::SecureMonitoring::Checks::Alive;  # by Default, the name of the check is build from this package name

use Moose;                                            # This is a Moose class ...
extends "PostgreSQL::SecureMonitoring::Checks";       # ... which extends our base check class

sub _build_sql { return "SELECT true;"; }             # this sub simply returns the SQL for the check

1;                                                    # every Perl module must return (end with) a true value

```

For more examples see the modules in `lib/PostgreSQL/SecureMonitoring/Checks` and the base class `PostgreSQL::SecureMonitoring::Checks` (in [lib/PostgreSQL/SecureMonitoring/Checks.pm](lib/PostgreSQL/SecureMonitoring/Checks.pm)).

More documentation is on the TODO list … ;-)


## Prerequisites

Posemo needs Perl 5 with Module::Build (only build/install time) DBI, DBD::Pg, Moose and some other modules. For development it is recommended to install a fresh Perl with [perlbrew](https://perlbrew.pl).

See and install all prerequisites:

```
perl Build.PL
./Build prereq_report       # show depencencies
./Build installdeps         # install all depencencies
```



##  Author

Posemo is written by [Alvar C.H. Freude](http://alvar.a-blast.org/), 2016–2017.

alvar@a-blast.org


## License

Posemo is released under the [PostgreSQL License](https://opensource.org/licenses/postgresql), a liberal Open Source license, similar to the BSD or MIT licenses.

See LICENSE.txt
