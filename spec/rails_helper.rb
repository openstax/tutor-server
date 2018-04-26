require 'simplecov'
require 'parallel_tests'
require 'codecov'

# Deactivate automatic result merging, because we use custom result merging code
SimpleCov.use_merging false

# Custom result merging code to avoid the many partial merges that SimpleCov usually creates
# and send to codecov only once
SimpleCov.at_exit do
  # Store the result for later merging
  SimpleCov::ResultMerger.store_result(SimpleCov.result)

  # All processes except one will exit here
  next unless ParallelTests.last_process?

  # Wait for everyone else to finish
  ParallelTests.wait_for_other_processes_to_finish

  # Send merged result to codecov only if on CI (will generate HTML report by default locally)
  SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['CI'] == 'true'

  # Merge coverage reports (and maybe send to codecov)
  SimpleCov::ResultMerger.merged_result.format!
end

# Start calculating code coverage
SimpleCov.start('rails') { merge_timeout 3600 }

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

# https://github.com/colszowka/simplecov/issues/369#issuecomment-313493152
# Load rake tasks so they can be tested
Rails.application.load_tasks unless defined?(Rake::Task) && Rake::Task.task_defined?('environment')

require 'openstax/salesforce/spec_helpers'
include OpenStax::Salesforce::SpecHelpers

require 'shoulda/matchers'

Capybara.server = :webrick

require 'selenium/webdriver'

# https://robots.thoughtbot.com/headless-feature-specs-with-chrome
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [ '--lang=en' ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

# no-sandbox is required for it to work with Docker (Travis)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [
    'headless', 'no-sandbox', 'disable-dev-shm-usage', 'lang=en'
  ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

Capybara.javascript_driver = :selenium_chrome_headless

Capybara.asset_host = 'http://localhost:3001'

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
  config.include UserAgentHelper
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
  #     RSpec.describe UsersController, type: :controller do
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
    metadata = self.class.metadata
    DatabaseCleaner.strategy = metadata[:js] || metadata[:truncation] ? :truncation : :transaction
    DatabaseCleaner.start
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

# Make the Boxr gem work with Webmock/VCR
RSpec.configure do |config|
  config.before(:suite) do
    Boxr.send :remove_const, 'BOX_CLIENT'
    Boxr::BOX_CLIENT = HTTPClient.new
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

def disable_sfdc_client
  allow(ActiveForce)
    .to receive(:sfdc_client)
    .and_return(double('null object').as_null_object)
end

def make_payment_required(student: nil, course: nil, user: nil)
  allow(Settings::Payments).to receive(:payments_enabled) { true }
  course.reload.update_attribute(:does_cost, true) if course.present?

  if student.nil?
    raise "user cannot be nil if student is nil" if user.nil?
    student = UserIsCourseStudent.call(user: user, course: course).outputs.student
  end

  Timecop.freeze(student.payment_due_at + 1.day) { yield }
end

def make_payment_required_and_expect_422(student: nil, course: nil, user: nil, &block)
  make_payment_required(student: student, course: course, user: user, &block)
  expect(response).to have_http_status(:unprocessable_entity)
end

def make_payment_required_and_expect_not_422(student: nil, course: nil, user: nil, &block)
  make_payment_required(student: student, course: course, user: user, &block)
  expect(response).not_to have_http_status(:unprocessable_entity)
end

def create_contract!(name)
  FinePrint::Contract.create! do |contract|
    contract.name    = name
    contract.version = 1
    contract.title   = name + ' title'
    contract.content = name + ' content'
  end
end
