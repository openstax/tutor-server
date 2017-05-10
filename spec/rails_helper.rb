require 'simplecov'
require 'codecov'
require 'parallel_tests'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Codecov
]) if ENV['CI'] == 'true'

SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

require 'openstax/salesforce/spec_helpers'
include OpenStax::Salesforce::SpecHelpers

require 'shoulda/matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/mocks/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include CaptureStdoutHelper
  config.include WithoutException
  config.include SigninHelper
  config.include PopulateExerciseContent
  config.extend VcrConfigurationHelper

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Use DatabaseCleaner instead of rspec transaction rollbacks
  # http://tomdallimore.com/blog/taking-the-test-trash-out-with-databasecleaner-and-rspec/

  config.prepend_before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.prepend_before(:all) do
    DatabaseCleaner.start
  end

  config.prepend_before(:all, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.prepend_before(:all, truncation: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.prepend_before(:all) do
    DatabaseCleaner.strategy = :transaction
  end

  config.prepend_before(:each) do
    DatabaseCleaner.start
  end

  # https://github.com/DatabaseCleaner/database_cleaner#rspec-with-capybara-example says:
  #   "It's also recommended to use append_after to ensure DatabaseCleaner.clean
  #    runs after the after-test cleanup capybara/rspec installs."
  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  config.append_after(:all) do
    DatabaseCleaner.clean
  end
end

# Adds a convenience method to get interpret the body as JSON and convert to a hash;
# works for both request and controller specs
class ActionDispatch::TestResponse
  def body_as_hash
    @body_as_hash_cache ||= JSON.parse(body, symbolize_names: true)
  end
end

RSpec::Matchers.define :have_routine_errors do
  include RSpec::Matchers::Composable

  match do |actual|
    actual.errors.any?
  end

  failure_message do |actual|
    "expected that #{actual} would have errors"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not have errors"
  end
end

RSpec::Matchers.define :have_routine_error do |error_code|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.errors.any?{|error| error.code == error_code}
  end

  failure_message do |actual|
    "expected that #{actual} would have error :#{error_code.to_s}"
  end
end

# https://gist.github.com/shime/9930893
RSpec::Matchers.define :be_the_same_time_as do |expected|
  match do |actual|
    expect(expected.strftime("%d-%m-%Y %H:%M:%S")).to eq(actual.strftime("%d-%m-%Y %H:%M:%S"))
  end
end

def fake_flash(key, value)
  flash_hash = ActionDispatch::Flash::FlashHash.new
  flash_hash[key] = value
  session['flash'] = flash_hash.to_session_value
end


def redirect_path
  redirect_uri.path
end

def redirect_path_and_query
  "#{redirect_uri.path}?#{redirect_uri.query}"
end

def redirect_query_hash
  Rack::Utils.parse_nested_query(redirect_uri.query).symbolize_keys
end

def redirect_uri
  expect(response.code).to eq "302"
  uri = URI.parse(response.headers["Location"])
end
