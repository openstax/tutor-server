require "rails_helper"

RSpec.describe "teacher logout", type: :request do
  let(:user)        { FactoryBot.create(:user) }
  let(:default) { OpenStax::Accounts.configuration.default_logout_redirect_url }

  it "redirects to accounts" do
    stub_current_user(user)
    allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
    host! 'tutor-blah.openstax.org'
    delete("/accounts/logout")
    expect(response).to redirect_to(default)
  end
end
