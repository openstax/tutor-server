require 'rails_helper'

RSpec.describe Domain::MapUsersAccounts do
  describe '.account_to_user' do
    let(:profile) { Domain::MapUsersAccounts.account_to_user(account) }

    context 'when the account is anonymous' do
      let(:account) { double(:account, is_anonymous?: true) }

      it 'returns an anonymous instance' do
        expect(profile).to be_a(UserProfile::Models::AnonymousUser)
      end
    end

    context 'when the account can find a matching profile' do
      let!(:found) { FactoryGirl.create(:profile) }
      let(:account) { double(:account, id: found.account_id, is_anonymous?: false) }

      it 'returns the profile' do
        expect(profile).to eq(found)
      end
    end

    context 'when a profile can be created successfully' do
      let(:account) { double(:account, id: 2, is_anonymous?: false) }

      it 'returns the created profile for the account' do
        expect(profile).to be_a(UserProfile::Models::Profile)
        expect(profile.account_id).to eq(2)
      end

      it "sets the profile's exchange_identifier" do
        expect(profile.exchange_identifier).to match(/^[a-fA-F0-9]+$/)
      end
    end
  end

  describe '.user_to_account' do
    it 'returns the associated profile account' do
      user = FactoryGirl.create(:user)
      expected = user.account

      result = Domain::MapUsersAccounts.user_to_account(user)

      expect(result.username).to eq(expected.username)
    end
  end
end
