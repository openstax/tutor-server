# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'date_time_utilities'
require 'acts_as_resource'
require 'acts_as_tasked'
require 'belongs_to_time_zone'
require 'html_tree_operations'
require 'verify_and_get_id_array'
require 'entity'
require 'wrapper'
require 'strategy_error'
require 'representable/coercion'
require 'env_utilities'
require 'settings'
require 'type_verification'
require 'tagger'
require 'unique_tokenable'
require 'url_generator'
require 'filename_sanitizer'
require 'logout_redirect_chooser'
require 'openstax_rescue_from_this'
require 'xlsx_utils'
require 'xlsx_helper'
require 'axlsx_modifications'
require 'default_time_validations'
require 'auto_uuid'
require 'json_serialize'
require 'configurable'
require 'term_year'

%w(biglearn cnx exercises).each do |oxlib|
  Dir[Rails.root.join("lib/openstax/#{oxlib}/#{oxlib}.rb")].each { |f| require f }
end

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

TUTOR_HELPDESK_URL = "http://openstax.force.com/support?l=en_US&c=Products%3ATutor"

# Initialize the Rails application.
Rails.application.initialize!

require 'doorkeeper_session_grant'
