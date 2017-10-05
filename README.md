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


For a simple check you may look below at the *Alive* Check, which simply returns true if the server is reachable. It uses a lot of defaults from `PostgreSQL::SecureMonitoring::Checks` and sugar from `PostgreSQL::SecureMonitoring::ChecksHelper`:

```
package PostgreSQL::SecureMonitoring::Checks::BackupAge;  # by Default, the name of the check is build from this package name

use PostgreSQL::SecureMonitoring::ChecksHelper;           # enables Moose, exports sugar functions; enables strict&warnings
extends "PostgreSQL::SecureMonitoring::Checks";           # We extend our base class ::Checks

check_has                                                 # all options and Code/SQL for the check
   return_type => 'integer',
   result_unit => 'seconds',
   code        => "SELECT CASE WHEN pg_is_in_backup()
                               THEN CAST(extract(EPOCH FROM statement_timestamp() - pg_backup_start_time()) AS integer)
                               ELSE NULL
                               END 
                          AS backup_age;";

1;                                                        # every Perl module must return (end with) a true value

```

For more examples see the modules in `lib/PostgreSQL/SecureMonitoring/Checks` and the base class `PostgreSQL::SecureMonitoring::Checks` (in [lib/PostgreSQL/SecureMonitoring/Checks.pm](lib/PostgreSQL/SecureMonitoring/Checks.pm)) (available in the dev branch!).

More documentation is on the TODO list … ;-)


## Prerequisites

Posemo needs (beside a PostgreSQL installation) Perl 5 with Module::Build (only build/install time) DBI, DBD::Pg, Moose and some other modules. For development it is recommended to install a fresh Perl with [perlbrew](https://perlbrew.pl).

See and install all prerequisites:

```
perl Build.PL
./Build prereq_report       # show depencencies
./Build installdeps         # install all depencencies
```

Sometimes some CPAN modules install/test not correctly; then you may run installdeps multiple times or install missing modules manually:

```
cpan Missing::ModuleName
```


## Test Driven Development

At time of this writing there exists no executables beside the tests. So, you can not run an executable and see results. You can only run some checks.

For testing you need a local PostgreSQL installation. We use a new testing module for starting/stopping/... PostgreSQL instances called `Test::PostgreSQL::Starter`, which is included (but will be an extra CPAN module later).

To start all the tests run:

```
./Build test               # at first time, you need to run perl Build.PL first 
```

Developers should set the environment variable `TEST_AUTHOR` to a true value.

You may want start only some tests:

```
./Build test test_files=t/[01]*       verbose=1   # install test server, verbose output
./Build test test_files=t/501-alive.* verbose=1   # runs tests of the alive check
./Build test test_files=t/99*         verbose=1   # stop test server
```



##  Author

Posemo is written by [Alvar C.H. Freude](http://alvar.a-blast.org/), 2016–2017.

alvar@a-blast.org


## License

Posemo is released under the [PostgreSQL License](https://opensource.org/licenses/postgresql), a liberal Open Source license, similar to the BSD or MIT licenses.

See LICENSE.txt
