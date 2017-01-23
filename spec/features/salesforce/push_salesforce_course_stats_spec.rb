require 'rails_helper'

RSpec.describe "push salesforce course stats", js: true do

  before(:all) do
    if !Salesforce::Models::User.any?
      @admin_user = FactoryGirl.create(:user, :administrator)
      page.driver.post("/accounts/dev/accounts/#{@admin_user.account.openstax_uid}/become")
debugger
      visit root_path
      visit admin_salesforce_path

      click_link "sign_in"

      debugger

      puts 'hi'
    end
  end

  after(:all) do
    Salesforce::Models::User.destroy_all
    @admin_user.destroy
  end

  it "does it" do

    debugger
    puts 'hi'

  end

end
