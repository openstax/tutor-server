# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'date_time_utilities'
require 'has_one_task_step'
require 'belongs_to_resource'

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

# Initialize the Rails application.
Rails.application.initialize!
