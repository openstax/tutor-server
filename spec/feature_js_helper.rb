# Monkey patching ActiveRecord::Base to use the same transaction for all threads
# http://rubydoc.info/github/jnicklas/capybara/master#Transactions_and_database_setup
class ActiveRecord::Base
  @@shared_connection = nil

  # Not thread-safe: call only in tests
  def self.connection
    return @@shared_connection if @@shared_connection.present? && @@shared_connection.active?
    @@shared_connection = super
  end
end

# Helper functions

def autocomplete(selector, with:)
  page.driver.evaluate_script("$('#{selector}').focus().val('#{with}').keydown();")
  expect(page).to have_css('.ui-autocomplete .ui-menu-item')
  page.driver.evaluate_script("$('.ui-autocomplete .ui-menu-item').click()")
end
