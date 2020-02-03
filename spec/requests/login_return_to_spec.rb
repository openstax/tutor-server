require "rails_helper"

RSpec.describe "Login with explicit return_to", type: :request do
  let(:user)        { FactoryBot.create(:user_profile) }

  good_return_tos = %w(http://www.cnx.org?blah http://localhost:3001 http://openstax.org)

  good_return_tos.each do |good_return_to|
    it "stores '#{good_return_to}'return_to redirect after login for approved return_tos" do
      stub_current_user(user)
      allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
      host! 'tutor-blah.openstax.org'
      get("/accounts/login?return_to=#{good_return_to}")
      expect(session["accounts_return_to"]).to eq good_return_to
    end
  end

  bad_return_tos = %w(http://www.openstax.org.spamsite.net http://www.openstax.org%0Aspamsite.net)

  bad_return_tos.each do |bad_return_to|
    it "does not store '#{bad_return_to}' return_to redirect after login for non-approved return_tos" do
      stub_current_user(user)
      allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
      host! 'tutor-blah.openstax.org'
      get("/accounts/login?return_to=#{bad_return_to}")
      expect(session["accounts_return_to"]).to eq nil
    end
  end
end
