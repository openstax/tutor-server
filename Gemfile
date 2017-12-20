# Copyright 2011-2014 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '4.2.7.1'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.3.7'

# SCSS stylesheets
gem 'sass-rails', '~> 5.0.0'

# Compass stylesheets
gem 'compass-rails'

# Automatically add browser-specific CSS prefixes
gem 'autoprefixer-rails'

# JavaScript asset compressor
gem 'uglifier', '>= 1.3.0'

# Detect browser being used in order to display a "Please upgrade" message
gem 'browser', '~> 2.5'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# JavaScript asset compiler
gem 'therubyracer', platforms: :ruby

# jQuery library
gem 'jquery-rails'

# Automatically ajaxify links
gem 'turbolinks'

# PostgreSQL database
gem 'pg'

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
gem 'openstax_accounts', '~> 7.11.0'

# Datetime parsing
gem 'chronic'

# API versioning and documentation
gem 'openstax_api', '~> 8.2.0'

gem 'apipie-rails'
gem 'maruku'

# LTI helper
gem 'ims-lti', '~> 2.2.1'

# API JSON rendering/parsing
# Do not use Roar 1.0.4
# Also, do not use Roar::Hypermedia links
gem 'roar', '1.0.3'

# Background job status store
gem 'jobba', '~> 1.6.0'

# Lev framework
gem 'lev', '~> 8.0.0'

# Ruby dsl for SQL queries
gem 'squeel'

# Contract management
gem 'fine_print', '~> 3.1.0'

# Keyword search
gem "keyword_search", github: 'openstax/keyword_search', ref: '21785cb0f644'

# File uploads
gem 'remotipart'
gem 'carrierwave'

# Image editing
gem 'mini_magick'

# Object cloning
gem 'deep_cloneable'

# Real time application monitoring
gem 'newrelic_rpm'

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
gem 'delayed_job_active_record'
gem 'daemons'

# Type coercion for Representable
gem 'virtus'

# Create xlsx files
gem 'axlsx', github: 'randym/axlsx', ref: 'c8ac844572b25fda358cc01d2104720c4c42f450'

# Pagination library
gem 'will_paginate', '~> 3.0.6'

# Time travel
gem 'timecop'

# Efficient mass imports
gem 'activerecord-import'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from', '~> 2.1.0'

# Generate memorable codes
gem 'babbler', '~> 1.0.1'

# Soft-deletion
gem 'paranoia'

# Salesforce
gem 'openstax_salesforce', '~> 1.1.0'
# Fork that supports Ruby >= 2.1 and stubbable stdout
gem 'active_force', git: 'https://github.com/openstax/active_force', ref: '7caac17'

# Global settings
gem 'rails-settings-cached', '~> 0.4.0'
gem 'rails-settings-ui'

# Nicely-styled static error pages
gem 'error_page_assets'
gem 'render_anywhere', require: false

# Add P3P headers for IE
gem 'p3p'

# API throttling
gem 'rack-attack'

# Minimize DB access due to touch: true associations
gem 'activerecord-delay_touching'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

# Per-request global storage
gem 'request_store'

# Use PostgreSQL cursors with ActiveRecord
gem 'postgresql_cursor'

# manage PostgresQL view migrations
gem 'scenic', '~> 1.4'

# Allows 'ap' alternative to 'pp' and 'ai' alternative to 'inspect'
gem 'awesome_print'

# Advisory Locks
# This version provides locks that unlock automatically at the end of the transaction,
# which are required for the correct operation of the Biglearn client
gem 'with_advisory_lock', git: 'https://github.com/procore/with_advisory_lock.git', ref: 'aba1583c'

# In place form editing on admin menu
gem 'best_in_place'

# Box integration
gem 'boxr'

# OAuth gem for generating and validating lti requests
gem 'oauth', '~> 0.5.1'

gem 'scout_apm', '~> 3.0.x'

group :development, :test do
  # Get env variables from .env file
  gem 'dotenv-rails'

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

  # Mute asset pipeline log messages
  gem 'quiet_assets'

  # Use RSpec for tests
  gem 'rspec-rails', '~> 3.0'

  gem 'rspec-collection_matchers'

  gem 'pilfer', '~> 1.0.0'

  # Fixture replacement
  gem 'factory_bot_rails'

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'

  # Testing excel files
  gem 'roo'

  # Speedup and run specs when files change
  gem 'spring'
  gem 'spring-commands-rspec'
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
  # Fake in-memory Redis for testing
  gem 'fakeredis'

  gem 'shoulda-matchers', require: false
  gem 'poltergeist'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'db-query-matchers'

  gem 'whenever-test'

  gem 'capybara-screenshot', require: false

  # Code Climate integration
  gem "codeclimate-test-reporter", require: false

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
