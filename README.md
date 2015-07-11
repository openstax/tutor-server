[![Code Climate](https://codeclimate.com/github/openstax/tutor-server.png)](https://codeclimate.com/github/openstax/tutor-server)
[![Build Status](https://travis-ci.org/openstax/tutor-server.png?branch=master)](https://travis-ci.org/openstax/tutor-server)
[![Coverage Status](https://img.shields.io/coveralls/openstax/tutor-server.svg)](https://coveralls.io/r/openstax/tutor-server)

# OpenStax testing logins

The demo tasks populate the server with a few students:

  * student-ak
  * student-hp
  * student-hg
  * student-cd
  * student-nz
  * student-ne
  * student-sd

The teacher login is: teacher-cm

# OpenStax Tutor Backend Server

## Configuring database for Development and Testing

OpenStax Tutor uses the Postgresql database.  You'll need to install and configure that.

`sudo apt-get install postgresql postgresql-client postgresql-contrib libpq-dev`

Or using homebrew on OSX

`brew install postgresql` or install from http://postgresapp.com

Once installed, create a user and database.  By default Tutor will expect a database named 'ox_tutor_{dev,test}' owned by user 'ox_tutor' who has a password 'ox_tutor_secret_password'.  These can be overridden by setting environmental variables in your ~/.bash_profile or ~/.zshenv.  See the config/database.yml for details.

`createuser --createdb --pwprompt ox_tutor`

And then create the development and test databases:

`createdb --username ox_tutor ox_tutor_dev`

`createdb --username ox_tutor ox_tutor_test`

## Error Pages/Responses

By default, the development and test environments see different error responses than the production environment does.
Dev and test environments will see HTML responses with backtraces and helpful debugging information; the production
environment will see nicely-formatted HTML error pages or simple JSON responses.

Our frontend developers will often use the development environment during testing but will likely want to see
production-like error responses.  To achieve this, set a `USE_DEV_ERROR_RESPONSES` to `false`.  This can be achieved
with a `.env` file in the root folder containing:

```
USE_DEV_ERROR_RESPONSES=false
```

A `.env.frontend_example` file is available in the repository for FE devs to copy over to `.env`.  The recommend
behavior is to do this and then only switch to a `true` setting if you need to debug (see backtraces, etc).

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
