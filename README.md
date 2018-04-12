[![Build Status](https://travis-ci.org/alvar-freude/Posemo?branch=master)](https://travis-ci.org/alvar-freude/Posemo)

# Posemo – PostgreSQL Secure Monitoring

Posemo is a PostgreSQL monitoring framework, that can monitor everything in Postgres with an unprivileged user, which has no access to any data. Posemo conforms to the rules of the *German Federal Office for Information Security* ([Bundesamt für Sicherheit in der Informationstechnik](https://www.bsi.bund.de/), BSI).

Posemo itself has no display capabilities, but can output the results for every monitoring environment (e.g. check_mk, Nagios, Zabbix, Icinga, …).

## This is a Pre-Release, for Developers only!

This is now a **usable** pre-release with limited checks. It is not feature comple. **See quick installation instructions below.**

More documentation will come. Posemo is in active development!

Some parts of the documentation are missing.


## Concepts

Posemo is a modular framework for creating monitoring checks for PostgreSQL. It is simple to add a new check. Usually just have to write the SQL for the check and add some configuration. And it is recommended, to write some tests for every check.

You may look in [PostgreSQL::SecureMonitoring::Checks](lib/PostgreSQL/SecureMonitoring/Checks) for the checks which are currently ready to use.

Posemo is a modern Perl application using Moose; at installation it generates PostgerSQL functions for every check. These functions are called by an unprivileged user who can only call there functions, nothing else. But since they are `SECURITY DEFINER` functions, they run with more privileges (usually as superuser, since PostgreSQL 10 as a user, which is member of `pg_monitor`). You need a superuser for installation, but checks can run (from remote or local) by an unprivileged user. Therefore, **the monitoring server need no access to your databases, no access to PostgreSQL internals – it can only call some predefined functions.**


For a simple check you may look below at the *Alive* Check, which simply returns always true. It uses a lot of defaults from `PostgreSQL::SecureMonitoring::Checks` and sugar from `PostgreSQL::SecureMonitoring::ChecksHelper`:

```perl
package PostgreSQL::SecureMonitoring::Checks::Alive;      # by Default, the name of the check is build from this package name


use PostgreSQL::SecureMonitoring::ChecksHelper;           # enables Moose, exports sugar functions; enables strict&warnings
extends "PostgreSQL::SecureMonitoring::Checks";           # We extend our base class ::Checks

check_has code => "SELECT true";                          # This is our check SQL!

1;                                                        # every Perl module must return (end with) a true value
```


A more advanced check is *BackupAge* check, which checks how long a backup is running and returns the seconds as integer:


```perl
package PostgreSQL::SecureMonitoring::Checks::BackupAge;  # same as above ...

use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

check_has                                                 # here more options and Code/SQL for the check
   return_type => 'integer',
   result_unit => 'seconds',
   code        => "SELECT CASE WHEN pg_is_in_backup()
                               THEN CAST(extract(EPOCH FROM statement_timestamp() - pg_backup_start_time()) AS integer)
                               ELSE NULL
                               END
                          AS backup_age;";

1;

```

For more examples see the modules in `lib/PostgreSQL/SecureMonitoring/Checks` and the base class `PostgreSQL::SecureMonitoring::Checks` (in [lib/PostgreSQL/SecureMonitoring/Checks.pm](lib/PostgreSQL/SecureMonitoring/Checks.pm)).

More documentation is on my TODO list … ;-)

### Users

Posemo needs two users: one superuser as owner of all check functions (or beginning with PostgreSQL 10.0: a user, which is member of `pg_monitor`) and an unprivileged user, which only can call the check functions.


## Installation

Posemo is written in modern Perl and is tested with 5.16 and up, but should also work with ancient versions down to 5.10. It needs some Perl modules as dependencies. Currently it is not available on CPAN or as package, so it doesn't install all dependencies automatically.

* Perl is usually installed by your OS. Some Linux distributions deliver broken Perl packages and maybe you should install the perl default modules `perl-modules`.
* If you don't want to (or can't) install all dependencies with the package manager of your OS, it may be better to install your own Perl to avoid conflicts with system packages. The best way is to use [perlbrew](http://perlbrew.pl) for this. The latest Perl without ithreads is fine.
* Posemo is not tested on Windows, but should work with [Strawberry Perl](http://strawberryperl.com)


### Perl modules

The following instructions assume, that you have a fresh perlbrew Perl installed, which is recommended at least for development. (A list of Debian/Ubuntu packages is in the file Build.PL at the end, this should work.)

You find a list of all dependencies in Build.PL.

Posemo uses `Module::Build` for building and testing. This is not included anymore in newer Perl versions, so you have to install it manually:

```
$ cpan Module::Build
```

Pull the latest version of Posemo and install all dependencies:


```
perl Build.PL               # generate Build script
./Build prereq_report       # (optionally) show depencencies
./Build installdeps         # install all depencencies
```

Sometimes some CPAN modules install/test not correctly; then you may run installdeps multiple times or install missing modules manually:

```
cpan Missing::ModuleName
```

When all dependencies are installed, you may start the tests, see below.


## Running Posemo Checks

Before running Posemo, all the check functions must be installed in a database. It is also recommended to use an own user and superuser only for the checks. The Posemo installer does everything. To install all checks with `posemo_install.pl` on the local host:

```
$ bin/posemo_install.pl --create_database --create_superuser --create_user
INFO : Install Posemo and Checks
INFO : INSTALL: create monitoring database 'monitoring'
INFO : INSTALL: create monitoring superuser 'monitoring_admin'
INFO : INSTALL: create monitoring user 'monitoring'
INFO : Install all check functions
INFO : Install all checks
INFO :   => Check Activity
INFO :   => Check Alive
INFO :   => Check BackupAge
INFO :   => Check Writeable
INFO : Posemo installed.
```

You can see all options with a short description via `--help` (Short: `-h`) or with default values via `--show_options`.

Now you can run the checks with `posemo_json.pl`:

```
$ bin/posemo_json.pl --pretty --outfile=monitoring-result.json
INFO : Run check Activity for host localhost
INFO : Run check Alive for host localhost
INFO : Run check Backup Age for host localhost
INFO : Run check Writeable for host localhost
```

You can see all options with a short description via `--help` (Short: `-h`) or with default values via `--show_options`.

Result is now in the outfile; if no outfile is given, then output goes to STDOUT. Messages (INFO, …) go to STDERR, so you can redirect them both.

For more complex configuration look into the examples in `conf/` or the tests in `t/`.



## Test Driven Development

For development, you usually don't run the real checks, but the test environment. It installs everything in a clean temporary PostgreSQL database (test files `t/[01]*`) and cleans it up after testing (test files `t/99*`).

For testing you need a local PostgreSQL installation. We use a new testing module for starting/stopping/... PostgreSQL instances called `Test::PostgreSQL::Starter`, which is included (but will be an extra CPAN module later).

The [pgTAP PostgreSQL extension](http://pgtap.org) ([pgTAP code on GitHub](https://github.com/theory/pgtap/)) is necessary too (installed in the local Postgres-Installation).

To start all the tests run:

```
./Build test               # at first time, you need to run perl Build.PL first
```

Developers should set the environment variable `TEST_AUTHOR` to a true value.

You may want run only some tests:

```
./Build test test_files=t/[01]*       verbose=1   # install test server, verbose output
./Build test test_files=t/501-alive.* verbose=1   # runs tests of the alive check
./Build test test_files=t/99*         verbose=1   # stop test server
```



##  Author

Posemo is written by [Alvar C.H. Freude](http://alvar.a-blast.org/), 2016–2018.

alvar@a-blast.org


## License

Posemo is released under the [PostgreSQL License](https://opensource.org/licenses/postgresql), a liberal Open Source license, similar to the BSD or MIT licenses.

See LICENSE.txt
