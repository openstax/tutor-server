[![Code Climate](https://codeclimate.com/github/openstax/tutor-server.png)](https://codeclimate.com/github/openstax/tutor-server)
[![Build Status](https://travis-ci.org/openstax/tutor-server.png?branch=master)](https://travis-ci.org/openstax/tutor-server)
[![Coverage Status](https://img.shields.io/coveralls/openstax/tutor-server.svg)](https://coveralls.io/r/openstax/tutor-server)

# OpenStax Tutor Backend Server


## Development

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
