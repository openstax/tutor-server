[![Build Status](https://travis-ci.org/openstax/tutor-server.png?branch=master)](https://travis-ci.org/openstax/tutor-server)
[![Coverage Status](https://img.shields.io/codecov/c/github/openstax/tutor-server.svg)](https://codecov.io/gh/openstax/tutor-server)

# OpenStax Tutor Backend Server

The following installations instructions assume you use APT (Linux) or Homebrew (OS X).
Please install the package management software appropriate for your OS, if necessary.
We also recommend getting the latest package definitions/Homebrew version using:

* Linux: `sudo apt-get update`
* OS X: `brew update`

You will need a specific version of `ruby` installed to run tutor-server.
We recommend using `rbenv` to manage your ruby versions
and `ruby-build` to compile new versions of ruby.

Follow the installation instructions for
[rbenv](https://github.com/rbenv/rbenv#installation) and
[ruby-build](https://github.com/rbenv/ruby-build#installation)

After installing all the prerequisites, `git clone` the tutor-server repository and `cd` into it:

```
git clone https://github.com/openstax/tutor-server.git
cd tutor-server
```

Then install the proper version of ruby using rbenv:

```
rbenv install 2.6.1
```

Make sure that `which ruby` and `which gem` point to your `.rbenv` folder,
NOT `/usr/bin` or `/usr/local/bin`.
If either of them are pointing to the wrong folder and you did modify your path according to
`rbenv`'s installation instructions, you might need to restart your shell.

Then install `bundler`:

```
gem install bundler
```

Once again, make sure that `which bundle` points to your `.rbenv` folder.
Restart your shell if that's not the case.

Then install the required gems:

```
bundle install
```

## Permanently setting environment variables

You can permanently set environment variables by creating a `.env` file in the tutor-server folder
containing your desired default environment variables and their values.
For an example, see the `.env.frontend_example` file.

## Configuring PostgreSQL for Development and Testing

OpenStax Tutor uses the PostgreSQL database. You'll need to install and configure that:

* Linux: `sudo apt-get install postgresql postgresql-client postgresql-contrib libpq-dev`
* OS X: `brew install postgresql`

Once installed, create a superuser for Tutor. By default Tutor will expect a user `ox_tutor`
who has a password `ox_tutor_secret_password`:

`createuser --superuser --pwprompt ox_tutor`

Then type `ox_tutor_secret_password` for the password in the prompt.

These PostgreSQL username and password for Tutor can be overridden by setting environment variables.
See the `config/database.yml` file for details.

You can tell Tutor to setup its databases:

`bin/rake db:setup`

If you ever need to clear the database contents, use:

`bin/rake db:reset`

If you end up with conflicts in your `schema.rb` file, run the following command
to re-create it from scratch:

`bin/rake db:drop db:create db:migrate db:seed`

If Tutor is still unable to connect to the database, you may have to update your `pg_hba.conf`.
Open that file with your favorite text editor:

* Linux: `sudo your-text-editor /etc/postgresql/<version>/main/pg_hba.conf`
* OS X: `sudo your-text-editor /usr/local/var/postgres/pg_hba.conf`

Change `peer` to `md5` or create a new `md5` entry for `localhost` (127.0.0.1).
Then restart the PostgreSQL daemons with:

* Linux: `sudo service postgresql restart`
* OS X: `sudo brew services restart postgresql`

Once Tutor is up and running the database superuser role can be safely removed from the user.
However, it is convenient to leave `ox_tutor` as a superuser so you can easily drop and re-create
its databases if necessary. To remove the superuser role:

```
psql -Uox_tutor ox_tutor_dev
ALTER USER ox_tutor NOSUPERUSER;
```

To quit the PostgreSQL shell, type `\q`.

## Configuring Redis server for Development and Testing

You will need a Redis server running in order to use tutor-server:

* Linux: `sudo apt-get install redis-server`
* OS X: `brew install redis`

If the server is remote (not running on localhost), it can be configured in `config/secrets.yml`.

## Starting tutor-server

Once PostgreSQL and Redis are configured, you can start the tutor-server process:

`bin/rails s`


By default, it will bind to port `3001` (so you can access it from https://localhost:3001).
You can specify a custom port with the `-p` command line option.
A development console is also available by running:

`bin/rails c`

## Error Pages/Responses

By default, the development and test environments
see different error responses than the production environment.
Dev and test environments will see HTML responses with backtraces and helpful debugging information,
but the production environment will see nicely-formatted HTML error pages or simple JSON responses.

Our frontend developers often use the development environment during testing
but will likely want to see production-like error responses.
To achieve this, set a `USE_DEV_ERROR_RESPONSES` environment variable to `false`.
This can be achieved by setting `USE_DEV_ERROR_RESPONSES=false` in your `.env` file.
A `.env.frontend_example` file is available in the repository for FE devs to copy over to `.env`.
The recommended behavior is to do this and then only switch to a `true` setting
if you need to debug the BE (see backtraces, etc).

## Background Jobs

Tutor in production runs background jobs using `delayed_job`.
In the development environment, however, background jobs are run "inline", i.e. in the foreground.

To actually run these jobs in the background in the development environment,
set the environment variable `USE_REAL_BACKGROUND_JOBS=true` in your `.env` file
and then start the `delayed_job` daemon:

`bin/rake jobs:work`

## Bullet

Bullet is a gem for finding N+1 queries and the like.  To enable it in development, set an
`ENABLE_BULLET` environment variable to `true`. Then you can tail `log/bullet.log`.
Beware that this will slow down the server considerably.

## Testing with capybara

Capybara-webkit depends on Qt. To install Qt:

* Linux: `sudo apt-get install qt5-default libqt5webkit5-dev`
* OS X: `brew install qt`

## Running specs in parallel

OpenStax Tutor can optionally run its specs using the
[parallel_tests](https://github.com/grosser/parallel_tests) gem.
This can result in the test suite completing 4-5 times faster
depending on how many CPU cores the testing environment has available.

To create the parallel test databases:

`bin/rake parallel:create parallel:prepare`

To upgrade the databases after migrations, run:

`bin/rake parallel:prepare`

If you had to solve migration or schema conflicts,
use the following commands to erase all data and start from scratch:

```
bin/rake db:drop db:create db:migrate db:seed
bin/rake parallel:drop parallel:create parallel:prepare
```

To run the test suite in parallel, use:

`bin/rake parallel:spec`

Be aware that canceling the parallel specs will NOT print the failed specs so far.
It can also leave some processes running that interfere with future test runs.
Kill them (and any other ruby processes) with `sudo killall -9 ruby`.

## Running Demos

A demo rake task exists to populate the database with certain courses and scenarios.
The demos assume that appropriate data has been loaded into CNX and Exercises.

Before running the task you should reset the database:

`bin/rake db:reset demo`

The courses that are set up in the demo are determined by the YAML files in the
[lib/tasks/demo](https://github.com/openstax/tutor-server/tree/master/lib/tasks/demo) directory.
It is in these files that you can configure different periods, student membership in periods,
CNX book UUID and version, assignments and progress on those assignments, etc.

By default, all YAML files in that directory are run (with the exception of `people.yml`).
If you want to only run one, you can specify its name in the rake call,
e.g. to load only the Biology course you would say:

`bin/rake db:reset demo[biology]`

One or more of the The YAML files can be copied to a different directory and customized.
They can then be run like so:

`CONFIG=../custom-config bin/rake db:reset demo`

Working the assignments may be skipped if the NOWORK variable is set:

`NOWORK=t bin/rake db:reset demo`

The book version can also be set:

`bin/rake db:reset demo[biology, latest]`

The course can be set to `all` to import all the available content,
and latest can be substituted with an explicit version, e.g. `4.4`.

As an admin you can search for the various users set up by the demo scripts
(or you can check out the demo YAML files in `/lib/tasks`).
For your convenience, here are a few of the student usernames and the courses they are setup with:

  * student01 - biology and physics
  * student02 - biology and physics
  * student03 - biology and physics
  * student08 - physics only
  * student09 - biology only
  * student31 - biology only
  * student33 - physics only

A teacher is setup with the `teacher01` username.

The full list of teachers and students can be
[found here](https://github.com/openstax/tutor-server/blob/master/lib/tasks/demo/people.yml).

Fastest way to get started `rake db:reset demo:content[mini]`.

## Profiling

See
[this napkin note](https://github.com/openstax/napkin-notes/blob/master/jp/profiling_tutor_server.md).

## Features and Associated Code

### LMS Integration

*Tutor Responsibilities*

1. Provide configuration info that lets teachers (later admins) configure Tutor within an LMS.
2. Handling the "launch" when an LMS directs one of its users to Tutor.
3. Sending scores back to the LMS.

*Feature Flags*

LMS integration within Tutor can be turned off/on by course-level feature flags.  Each course has a
`is_lms_enabling_allowed` flag and an `is_lms_enabled` flag.  Admins control the former, teachers control
the latter.  In order for a teacher to enable LMS integration, the `is_lms_enabling_allowed` flag must
be `true`.  Admins can search by this flag and bulk set this flag on any admin course search query results.

*Major Code Files*

1. `app/controllers/lms_controller.rb` - Runs launches and provides config info when installing the Tutor app in an LMS.
2. `app/controllers/api/v1/lms_controller.rb` - How the FE gets a course's LMS keys and triggers sending of scores to the LMS.
3. `app/subsystems/lms/launch.rb` - wraps and interprets launch HTTP requests and provides convenience methods to interact with Tutor's LMS models.
4. `app/subsystems/lms/send_course_scores.rb` - background job that sends scores to the LMS
5. `app/subsystems/lms/models/...` - DB models that wrap LMS related data we need to persist
