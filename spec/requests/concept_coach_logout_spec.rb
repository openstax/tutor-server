require "rails_helper"

RSpec.describe "Concept Coach teacher logout", type: :request do
  let(:user)    { FactoryBot.create(:user) }
  let(:default) { OpenStax::Accounts.configuration.default_logout_redirect_url }

  it "redirects to cc.openstax.org when the request is a CC one" do
    stub_current_user(user)
    allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
    host! 'tutor-blah.openstax.org'
    delete("/accounts/logout?cc=1")
    expect(response).to redirect_to(default + "?cc=1")
  end

  it "redirects to accounts when the request is NOT a CC one" do
    stub_current_user(user)
    allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
    host! 'tutor-blah.openstax.org'
    delete("/accounts/logout")
    expect(response).to redirect_to(default)
  end
end
