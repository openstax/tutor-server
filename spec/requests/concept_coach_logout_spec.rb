require "rails_helper"

describe "Concept Coach teacher logout", type: :request do
  let(:user)        { FactoryGirl.create(:user) }

  it "redirects to cc.openstax.org when the request is a CC one" do
    stub_current_user(user)
    host! 'tutor-blah.openstax.org'
    delete("/accounts/logout?cc=1")
    expect(response).to redirect_to("http://cc.openstax.org/logout-blah")
  end

  it "redirects to accounts when the request is NOT a CC one" do
    stub_current_user(user)
    host! 'tutor-blah.openstax.org'
    delete("/accounts/logout")
    expect(response).to redirect_to(OpenStax::Accounts.configuration.default_logout_redirect_url)
  end
end
