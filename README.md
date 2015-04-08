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

`createuser --createdb --pwprompt ox_tutor`

And then create the development and test databases:

`createdb --username ox_tutor ox_tutor_dev`

`createdb --username ox_tutor ox_tutor_test`

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
