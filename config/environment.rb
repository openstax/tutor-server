# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'date_time_utilities'
require 'belongs_to_resource'
require 'has_one_task_step'
require 'has_one_exercise_step'

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

# Initialize the Rails application.
Rails.application.initialize!
