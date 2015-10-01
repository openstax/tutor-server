[![Code Climate](https://codeclimate.com/github/openstax/tutor-server.png)](https://codeclimate.com/github/openstax/tutor-server)
[![Build Status](https://travis-ci.org/openstax/tutor-server.png?branch=master)](https://travis-ci.org/openstax/tutor-server)
[![Coverage Status](https://img.shields.io/coveralls/openstax/tutor-server.svg)](https://coveralls.io/r/openstax/tutor-server)

# OpenStax Tutor Backend Server

## Configuring database for Development and Testing

OpenStax Tutor uses the Postgresql database.  You'll need to install and configure that.

`sudo apt-get install postgresql postgresql-client postgresql-contrib libpq-dev`

Or using homebrew on OSX

`brew install postgresql` or install from http://postgresapp.com

Once installed, create a user and database.  By default Tutor will expect a database named 'ox_tutor_{dev,test}' owned by user 'ox_tutor' who has a password 'ox_tutor_secret_password'.  These can be overridden by setting environmental variables in your ~/.bash_profile or ~/.zshenv.  See the config/database.yml for details.

`createuser --superuser --pwprompt ox_tutor`

And then create the development and test databases:

`createdb --username ox_tutor ox_tutor_dev`

`createdb --username ox_tutor ox_tutor_test`

Once Tutor is up and running the database superuser role can be safely removed from the user. It is only needed to create and configure the tutor databases.  To remove it, log into the database:

`psql -Uox_tutor ox_tutor_dev`

and then run command: `alter user ox_tutor nosuperuser;`

Exit the psql database shell by typeing `\q` and hitting enter.

## Configuring database for Development and Testing

You will need a Redis server running in order to use tutor-server.
If you have Homebrew, `brew install redis` will usually take care of that.
If the server is not running on localhost, it can be configured in config/secrets.yml.

## Error Pages/Responses

By default, the development and test environments see different error responses than the production environment does.
Dev and test environments will see HTML responses with backtraces and helpful debugging information; the production
environment will see nicely-formatted HTML error pages or simple JSON responses.

Our frontend developers will often use the development environment during testing but will likely want to see
production-like error responses.  To achieve this, set a `USE_DEV_ERROR_RESPONSES` environment variable to `false`.  This can be achieved
with a `.env` file in the root folder containing:

```
USE_DEV_ERROR_RESPONSES=false
```

A `.env.frontend_example` file is available in the repository for FE devs to copy over to `.env`.  The recommend
behavior is to do this and then only switch to a `true` setting if you need to debug (see backtraces, etc).

## Background Jobs

Tutor in production runs background jobs using resque and redis.  In the development environment, however, background jobs are run "inline", i.e. not in the background.  To actually run these jobs in the background in the development environment, set the environment variable `USE_REAL_BACKGROUND_JOBS` to `true`.

## Bullet

Bullet is a gem for finding N+1 queries and the like.  To enable it in development, set an `ENABLE_BULLET` environment variable to `true`.  Then you can tail `log/bullet.log`.  Beware that this will slow down the server considerably.

## Testing with capybara

Capybara-webkit depends on Qt.  If you don't have Qt installed, you can install
it using `apt-get` on Debian or Ubuntu:

```
sudo apt-get install qt5-default libqt5webkit5-dev
```

or `homebrew` on OS X:

```
brew update
brew install qt
```

```
bundle install --without production
rake db:migrate
rake db:seed
rails server
```

## Running specs in parallel

OpenStax Tutor can optionally run it's specs using the [parallel_tests](https://github.com/grosser/parallel_tests) gem.  This can result in the test suite completing 2-3 times faster depending on how many CPU cores the testing environment has available.

To use the feature, run `rake parallel:create`.  This will create multiple copies of the database, one for each CPU core.  This command needs to be ran only once.

After creating the databases and after changing any of the migrations, run `rake parallel:prepare` to copy the database schema to each of them.

`rake parallel:spec` can then be used to run the testing suite in parallel.

## Running Demos

A demo rake task exists to populate the database with certain courses and scenarios.  The demos assume that appropriate data has been loaded into CNX and Exercises.  Before running the task you should drop the database and reload it:

`bundle exec rake db:reset demo`

The courses that are set up in the demo are determined by the YAML files in the [lib/tasks/demo](https://github.com/openstax/tutor-server/tree/master/lib/tasks/demo) directory.  It is in these files that you can configure different periods, student membership in periods, CNX book UUID and version, assignments and progress on those assignments, etc.

By default, all YAML files in that directory are run (with the exception of `people.yml`).  If you want to only run one, you can specify its name in the rake call, e.g. to load only the Biology course you would say:

`bundle exec rake db:reset demo[biology]`

One or more of the The YAML files can be copied to a different directory and customized.  They can then be ran by setting the CONFIG variable like so: `CONFIG=../custom-config bundle exec rake db:reset demo[biology]`

Working the assignments may be skipped if the NOWORK variable is set: `NOWORK=t bundle exec rake db:reset demo`

The book version can be set:

`bundle exec rake db:reset demo[biology, latest]` The course can be set to `all` to import all the available content, and latest can be substituted with an explicit version i.e. `4.4`.

As an admin you can search for the various users set up by the demo scripts (or you can check out the demo YAML files in `/lib/tasks`).  For your convenience, here are a few of the student usernames and the courses they are setup with:

  * student01 - biology and physics
  * student02 - biology and physics
  * student03 - biology and physics
  * student08 - physics only
  * student09 - biology only
  * student31 - biology only
  * student33 - physics only

A teacher is setup with username: `teacher01`

The full list of teachers and students can be [found here](https://github.com/openstax/tutor-server/blob/master/lib/tasks/demo/people.yml).

## Profiling

See [this napkin note](https://github.com/openstax/napkin-notes/blob/master/jp/profiling_tutor_server.md)
