require 'rails_helper'

RSpec.describe User::CreateUser, type: :routine do
  it 'requires a username' do
    expect { described_class[] }.to raise_error(ArgumentError)

    expect { described_class[username: 'something'] }.not_to raise_error
  end

  it 'does not require the username if the account_id is present' do
    account = FactoryBot.create(
      :openstax_accounts_account, username: 'account', openstax_uid: 'abc123'
    )

    expect { described_class[account_id: account.id] }.not_to raise_error
  end

  it 'creates a new user profile' do
    expect { described_class[username: 'blah'] }.to change { User::Models::Profile.count }.by(1)
  end

  it 'creates an account when an account_id is not passed' do
    expect do
      described_class[username: 'blah']
    end.to change { OpenStax::Accounts::Account.count }.by(1)

    OpenStax::Accounts::Account.destroy_all

    account = FactoryBot.create(
      :openstax_accounts_account, username: 'account', openstax_uid: 'something'
    )

    expect do
      described_class[account_id: account.id]
    end.not_to change { OpenStax::Accounts::Account.count }
  end
end
