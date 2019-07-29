# Copyright 2011-2014 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '~> 5.2.2'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.3.7'

# SCSS stylesheets
gem 'sass-rails', '~> 5.0.7'

# Compass stylesheets
gem 'compass-rails', '~> 3.1.0'

# JavaScript asset compressor
gem 'uglifier', '>= 1.3.0'

# Detect browser being used in order to display a "Please upgrade" message
gem 'browser', '~> 2.5'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2.2'

# JavaScript asset compiler
gem 'mini_racer'

# jQuery library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Automatically ajaxify links
gem 'turbolinks'

# PostgreSQL database
gem 'pg', '~> 1.1.4'

# Run unicorn when using the `rails server` or `rails s` command
gem 'unicorn-rails'

# Prevent server memory from growing until OOM
gem 'unicorn-worker-killer'

# Rails 5 HTML sanitizer
gem 'rails-html-sanitizer', '~> 1.0'

# URI replacement
gem 'addressable'

# Utilities for OpenStax websites
gem 'openstax_utilities', '~> 4.2.0'

# Cron job scheduling
gem 'whenever'

# Talks to Accounts (latest version is broken)
gem 'omniauth-oauth2', '~> 1.3.1'

# OpenStax Accounts integration
gem 'openstax_accounts', github: 'openstax/accounts-rails',
                         ref: '5c4fda619a738e04b26c44db5b412c772c389fbf'
gem 'action_interceptor'

# Datetime parsing
gem 'chronic'

# API versioning and documentation
gem 'openstax_api'

gem 'apipie-rails'
gem 'maruku'

# LTI helper
gem 'ims-lti', '~> 2.2.1'

# API JSON rendering/parsing
# Do not use Roar 1.0.4
# Also, do not use Roar::Hypermedia links
gem 'roar', '~> 1.1.0'

gem 'nokogiri'

# Background job status store
gem 'jobba', '~> 1.8.0'

# Lev framework
gem 'lev', '~> 9.0.1'

# Contract management
gem 'fine_print'

# Keyword search
gem 'keyword_search', github: 'openstax/keyword_search',
                      ref: '0ce23c42575129b74c14add9e5d069ef9fedebac'

# File uploads
gem 'remotipart'
gem 'carrierwave'

# Image editing
gem 'mini_magick'

# code editing
gem 'codemirror-rails'

# Object cloning
gem 'deep_cloneable'

# Date validations
gem 'validates_timeliness'

# JSON schema validation
gem 'json-schema', '~> 2.8.0'

# Cooler hashes
gem 'hashie'

# For calling JSON APIs
gem 'httparty'

# Ordered models
gem 'sortability'

# Lorem Ipsum
gem 'faker'

# Key-value store for caching
gem 'redis-rails'

# Background job queueing
gem 'delayed_job_active_record', '~> 4.1.4.beta1'
gem 'daemons'

# Type coercion for Representable
gem 'virtus'

# Create xlsx files
gem 'axlsx', github: 'randym/axlsx', ref: 'c8ac844572b25fda358cc01d2104720c4c42f450'

# Pagination library
gem 'will_paginate', '~> 3.1.7'

# Time travel
gem 'timecop'

# Efficient mass imports
gem 'activerecord-import'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from'


# Sentry integration (the require disables automatic Rails integration since we use rescue_from)
gem 'sentry-raven', require: 'raven/base'

# Generate memorable codes
gem 'babbler', '~> 1.0.1'

# Soft-deletion
gem 'paranoia', '~> 2.4.1'

# Salesforce
gem 'openstax_salesforce'

# Fork that supports Ruby >= 2.1 and stubbable stdout
gem 'active_force', github: 'openstax/active_force', ref: '3ba34211b6f2387b5e05512b9561076894c5fa2d'

# Global settings
gem 'rails-settings-cached'
gem 'rails-settings-ui'

# Nicely-styled static error pages
gem 'error_page_assets'
gem 'render_anywhere', require: false

# Add P3P headers for IE
gem 'p3p'

# API throttling
gem 'rack-attack'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

# Per-request global storage
gem 'request_store'

# Use PostgreSQL cursors with ActiveRecord
gem 'postgresql_cursor', '~> 0.6.2'

# In place form editing on admin menu
gem 'best_in_place'

# Box integration
gem 'boxr'

# OAuth gem for generating and validating lti requests
gem 'oauth', '~> 0.5.1'

gem 'scout_apm', '~> 3.0.x'

# Respond to ELB healthchecks in /ping and /ping/
gem 'openstax_healthcheck'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.4.0', require: false

group :development, :test do
  # Allows 'ap' alternative to 'pp' and 'ai' alternative to 'inspect'
  gem 'awesome_print'

  # Get env variables from .env file
  gem 'dotenv-rails'

  # lint files
  gem 'rubocop'

  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'
  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Call 'binding.pry' anywhere in the code to stop execution and get a debugger console
  gem 'pry' # needed when debugging without 'rails_helper'
  gem 'pry-nav'
  gem 'pry-rails'
  gem 'pry-stack_explorer'

  # Nail down n+1 queries and unused eager loading
  gem 'bullet'

  # Use RSpec for tests
  gem 'rspec-rails'

  gem 'rspec-collection_matchers'

  gem 'pilfer'

  # Fixture replacement
  gem 'factory_bot_rails'

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'

  # Testing excel files
  gem 'roo'

  # Speedup rails commands and rspec
  gem 'spring'
  gem 'spring-commands-rspec'

  # Run bundle install and specs when files change
  gem 'guard-bundler'
  gem 'guard-rspec'

  # Trace AR queries
  gem 'active_record_query_trace'
end

group :development do
  # Automated security checks
  gem 'brakeman'

  # Command line reference
  gem 'cheat'

  # CoffeeScript source maps
  gem 'coffee-rails-source-maps'

  # Assorted generators
  gem 'nifty-generators'

  # Class diagrams
  gem 'rails-erd'
  gem 'railroady'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console'
end

group :test do
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'

  gem 'launchy'
  gem 'database_cleaner'
  gem 'db-query-matchers'

  # Fake in-memory Redis for testing
  gem 'fakeredis'

  gem 'whenever-test'

  gem 'chromedriver-helper'

  gem 'capybara'
  gem 'capybara-selenium'
  gem 'capybara-screenshot', require: false

  # Codecov integration
  gem 'codecov', require: false
end

group :production do
  # AWS SES
  gem 'aws-ses', '~> 0.6.0', require: 'aws/ses'

  # Fog AWS
  gem 'fog-aws'

  # Lograge for consistent logging
  gem 'lograge'
end
