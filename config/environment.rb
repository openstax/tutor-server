# Load the Rails application.
require_relative 'application'
require 'demo'
require 'scout_helper'
require 'box'
require 'i_am'
require 'date_time_utilities'
require 'active_record/indestructible_record'
require 'acts_as_resource'
require 'acts_as_tasked'
require 'has_timezone'
require 'html_tree_operations'
require 'verify_and_get_id_array'
require 'representable/coercion'
require 'env_utilities'
require 'settings'
require 'type_verification'
require 'tagger'
require 'unique_tokenable'
require 'url_generator'
require 'filename_sanitizer'
require 'logout_redirect_chooser'
require 'xlsx_utils'
require 'xlsx_helper'
require 'axlsx_modifications'
require 'default_time_validations'
require 'auto_uuid'
require 'json_serialize'
require 'configurable'
require 'hypothesis'
require 'term_year'
require 'values_table'
require 'shared_course_search_helper'

%w(biglearn cnx exercises payments).each do |oxlib|
  Dir[Rails.root.join("lib/openstax/#{oxlib}/#{oxlib}.rb")].each { |f| require f }
end

SITE_NAME = "OpenStax Tutor"
COPYRIGHT_HOLDER = "Rice University"

TUTOR_HELPDESK_URL = "https://openstax.secure.force.com/help"
TUTOR_CONTACT_SUPPORT_URL = "#{TUTOR_HELPDESK_URL}/articles/FAQ/OpenStax-Tutor-Beta-customer-support-information"
TUTOR_INTEGRATE_LMS_URL = "#{TUTOR_HELPDESK_URL}/articles/FAQ/LMS-integration-for-OpenStax-Tutor-Beta"

# Initialize the Rails application.
Rails.application.initialize!
