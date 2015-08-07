require 'capybara'

Capybara.javascript_driver = :webkit

# monkey patching ActiveRecord::Base to use the same transaction for all threads
# http://rubydoc.info/github/jnicklas/capybara/master#Transactions_and_database_setup
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# Helper functions

def autocomplete(selector, with:)
  page.driver.evaluate_script("$('#{selector}').focus().val('#{with}').keydown();")
  expect(page).to have_css('.ui-autocomplete .ui-menu-item')
  page.driver.evaluate_script("$('.ui-autocomplete .ui-menu-item').click()")
end
