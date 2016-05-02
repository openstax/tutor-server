# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'date_time_utilities'
require 'acts_as_resource'
require 'acts_as_tasked'
require 'html_tree_operations'
require 'verify_and_get_id_array'
require 'entity'
require 'wrapper'
require 'strategy_error'
require 'representable/coercion'
require 'env_utilities'
require 'settings'
require 'course_guide_methods'
require 'type_verification'
require 'tagger'
require 'unique_tokenable'
require 'url_generator'
require 'filename_sanitizer'
require 'logout_redirect_chooser'
require 'openstax_rescue_from_this'
require 'active_job/base_with_retry_conditions'
require 'xlsx_helper'
require 'axlsx_modifications'

%w(
  biglearn
  cnx
  exercises
).each do |oxlib|
  Dir[Rails.root.join("lib/openstax/#{oxlib}/#{oxlib}.rb")].each { |f| require f }
end

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

# Initialize the Rails application.
Rails.application.initialize!

require 'doorkeeper_session_grant'
