# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'date_time_utilities'
require 'acts_as_resource'
require 'acts_as_tasked'
require 'html_tree_operations'
require 'fake_store'
require 'verify_and_get_id_array'
require 'entity'
require 'representable/coercion'
require 'chapter_section_formatter'
require 'env_utilities'

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

# Initialize the Rails application.
Rails.application.initialize!
