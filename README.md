[![Code Climate](https://codeclimate.com/github/openstax/tutor-server.png)](https://codeclimate.com/github/openstax/tutor-server)
[![Build Status](https://travis-ci.org/openstax/tutor-server.png?branch=master)](https://travis-ci.org/openstax/tutor-server)
[![Coverage Status](https://img.shields.io/coveralls/openstax/tutor-server.svg)](https://coveralls.io/r/openstax/tutor-server)

# OpenStax Tutor Backend Server


## Development

```
bundle install --without production
rake db:migrate
rake db:seed
rails generate secrets
rails server
```
