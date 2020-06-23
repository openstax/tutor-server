require "rails_helper"

RSpec.describe OpenStax::Accounts::SessionsController, type: :request do
  let(:user)    { FactoryBot.create(:user_profile) }

  context '#login' do
    good_return_tos = %w(http://www.cnx.org?blah http://localhost:3001 http://openstax.org)
    good_return_tos.each do |good_return_to|
      it "stores '#{good_return_to}' return_to redirect after login" do
        stub_current_user(user)
        allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
        host! 'tutor-blah.openstax.org'
        get openstax_accounts.login_url(return_to: good_return_to)
        expect(session["accounts_return_to"]).to eq good_return_to
      end
    end

    bad_return_tos = %w(http://www.openstax.org.spamsite.net http://www.openstax.org%0Aspamsite.net)
    bad_return_tos.each do |bad_return_to|
      it "does not store '#{bad_return_to}' return_to redirect after login" do
        stub_current_user(user)
        allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
        host! 'tutor-blah.openstax.org'
        get openstax_accounts.login_url(return_to: bad_return_to)
        expect(session["accounts_return_to"]).to eq nil
      end
    end
  end

  context '#logout' do
    it 'redirects to accounts' do
      stub_current_user(user)
      allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?) { false }
      host! 'tutor-blah.openstax.org'
      delete openstax_accounts.logout_url
      expect(response).to redirect_to(OpenStax::Accounts.configuration.default_logout_redirect_url)
    end
  end
end
