require 'rails_helper'

RSpec.describe MapUsersAccounts, type: :routine do
  describe '.account_to_user' do
    let(:user) { MapUsersAccounts.account_to_user(account) }

    context 'when the account is anonymous' do
      let(:account) do
        OpenStax::Accounts::FindOrCreateAccount.call(username: 'account').account
      end

      before { allow(account).to receive(:is_anonymous?) { true } }

      it 'returns an anonymous instance' do
        expect(user.is_anonymous?).to be true
      end
    end

    context 'when the account can find a matching user' do
      let!(:found)  { FactoryGirl.create(:user) }
      let(:account) { found.account }

      it 'returns the user' do
        expect(user).to eq(found)
      end
    end

    context 'when a user can be created successfully' do
      let(:account) do
        OpenStax::Accounts::FindOrCreateAccount.call(username: 'account').account
      end

      it 'returns the created user for the account' do
        expect(user).to be_a(User::User)
        expect(user.account).to eq(account)
      end

      it "sets the user's exchange identifiers" do
        expect(user.exchange_read_identifier).to match(/^[a-fA-F0-9]+$/)
        expect(user.exchange_write_identifier).to match(/^[a-fA-F0-9]+$/)
      end
    end
  end

  describe '.user_to_account' do
    it 'returns the associated user account' do
      user = FactoryGirl.create(:user)

      account = MapUsersAccounts.user_to_account(user)

      expect(account).to eq(user.account)
    end
  end
end
