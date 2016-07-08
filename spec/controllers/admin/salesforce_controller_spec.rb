require 'rails_helper'

RSpec.describe Admin::SalesforceController, type: :controller do
  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  describe 'callback' do
    context 'when there is not yet a SF user' do
      it 'adds a user' do
        allow_any_instance_of(described_class)
          .to receive(:env)
          .and_return(omniauth_env_hash)

        expect{post :callback}.to change {Salesforce::Models::User.count}.by(1)
      end
    end

    context 'when there are other SF users' do
      it 'adds a user and removes existing users' do
        FactoryGirl.create(:salesforce_user)
        FactoryGirl.create(:salesforce_user)

        allow_any_instance_of(described_class)
          .to receive(:env)
          .and_return(omniauth_env_hash)

        expect{post :callback}.to change {Salesforce::Models::User.count}.by(-1)
      end
    end
  end

  describe 'destroy_user' do
    it 'destroys users' do
      FactoryGirl.create(:salesforce_user)
      expect{delete :destroy_user}.to change {Salesforce::Models::User.count}.by(-1)
    end
  end

  describe 'import_courses' do
    it 'receives the call and formats the flash' do
      expect(ImportSalesforceCourses)
        .to receive(:call)
        .with(include_real_salesforce_data: false)

      allow(ImportSalesforceCourses)
        .to receive(:call)
        .with(include_real_salesforce_data: false)
        .and_return(
          OpenStruct.new(num_failures: 1, num_successes: 2)
        )

      post :import_courses, use_real_data: false

      expect(flash[:notice].gsub(/[^0-9]/, '')).to eq "321"
    end
  end

  def omniauth_env_hash
    {
      "omniauth.auth" => Hashie::Mash.new({
        uid: 'someuid',
        info: {
          name: 'Bobby Thomas',
        },
        credentials: {
          token: 'oauth_token',
          refresh_token: 'refresh_token',
          instance_url: 'http://blah.com/'
        }
      })
    }
  end
end
