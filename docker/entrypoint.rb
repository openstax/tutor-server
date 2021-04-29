#!/usr/bin/env ruby

# Require gems and initialize the application
require File.expand_path('../config/application', __dir__)

# Load rake tasks for the application
Rails.application.load_tasks

# Load the database config from config/database.yml
Rake::Task['db:load_config'].invoke

begin
  # Check if the database exists
  ActiveRecord::Base.establish_connection

  # Skipped when no database
  Rake::Task['db:migrate'].invoke
rescue ActiveRecord::NoDatabaseError
  # Create a new database and load the schema
  Rake::Task['db:setup'].invoke

  # Check if any migrations need to run, in case the schema is not up to date
  Rake::Task['db:migrate'].reenable
  Rake::Task['db:migrate'].invoke

  # Create the mini book using the demo script, with inline background jobs
  ENV['USE_REAL_BACKGROUND_JOBS'] ||= 'false'
  Rake::Task['demo'].invoke 'mini'
end

CourseProfile::BuildPreviewCourses.call(desired_count: 2)

# If this script was called with arguments, exec that as a command (this line never returns)
exec(*ARGV) unless ARGV.empty?
