# Copyright 2011-2014 Rice University. Licensed under the Affero General Public 
# License version 3 or later.  See the COPYRIGHT file for details.

source 'https://rubygems.org'

# Rails framework
gem 'rails', '4.2.0.beta1'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.2.0'

# SCSS stylesheets
gem 'sass-rails', '~> 5.0.0.beta1'

# Compass stylesheets
gem 'compass-rails'

# Automatically add browser-specific CSS prefixes
gem 'autoprefixer-rails'

# JavaScript asset compressor
gem 'uglifier', '>= 1.3.0'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# JavaScript asset compiler
gem 'therubyracer', platforms: :ruby

# jQuery library
gem 'jquery-rails'

# jQuery UI library
gem 'jquery-ui-rails'

# Automatically ajaxify links
gem 'turbolinks'

# Rails 5 HTML sanitizer
gem 'rails-html-sanitizer', '~> 1.0'

# Utilities for OpenStax websites
gem 'openstax_utilities', '~> 3.0.0'

# Cron job scheduling
gem 'whenever'

# OpenStax Accounts integration
gem 'openstax_accounts', '~> 3.1.0'

# Access control for API's
gem 'doorkeeper'

# Respond_with and respond_to methods
gem 'responders', '~> 2.0'

# API versioning and documentation
gem 'openstax_api'
gem 'apipie-rails'
gem 'maruku'
gem 'representable'
gem 'roar-rails'

# Lev framework
gem 'lev'

# Ruby dsl for SQL queries
gem 'squeel'

# Contract management
gem 'fine_print'

# Keyword search
gem "keyword_search"

# File uploads
gem 'remotipart'
gem 'carrierwave'

# Image editing
gem 'mini_magick'

# Embedded JavaScript templates
gem 'ejs'

# Embedded CoffeeScript templates
gem 'eco'

# Object tagging
gem 'acts-as-taggable-on'

# Object cloning
gem 'deep_cloneable'

# Object comments
gem 'commontator'

# Comment voting
gem 'acts_as_votable'

# Real time application monitoring
gem 'newrelic_rpm'

# YAML database backups
gem 'yaml_db'

group :development, :test do
  # Thin development server
  gem 'thin'

  # SQLite3 development database
  gem 'sqlite3'

  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console', '~> 2.0.0.beta2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Mute asset pipeline log messages
  gem 'quiet_assets'

  # Use RSpec for tests
  gem 'rspec-rails'

  # Fixture replacement
  gem 'factory_girl_rails'

  # Lorem Ipsum
  gem 'faker'

  # Automated security checks
  gem 'brakeman'

  # Time travel gem
  gem 'timecop'

  # Command line reference
  gem 'cheat'

  # Assorted generators
  gem 'nifty-generators'

  # Class diagrams
  gem 'rails-erd'
  gem 'railroady'

  # CoffeeScript source maps
  gem 'coffee-rails-source-maps'

  # Capistrano integration
  gem 'capistrano-rails'

  # Code Climate integration
  gem "codeclimate-test-reporter", require: false

  # Coveralls integration
  gem 'coveralls', require: false
end

group :production do
  # Unicorn production server
  gem 'unicorn'

  # PostgreSQL production database
  gem 'pg'

  # Notify developers of Exceptions in production
  gem 'exception_notification'
end
