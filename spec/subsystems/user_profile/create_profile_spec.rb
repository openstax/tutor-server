require 'rails_helper'

RSpec.describe UserProfile::CreateProfile do
  it 'requires a username' do
    expect {
      described_class[]
    }.to raise_error

    expect {
      described_class[username: 'something']
    }.not_to raise_error
  end

  it 'does not require the username if the account_id is present' do
    account = OpenStax::Accounts::Account.create!(username: 'account',
                                                  openstax_uid: 'abc123')
    expect {
      described_class[account_id: account.id]
    }.not_to raise_error
  end

  it 'creates an entity user when an id is not passed' do
    expect {
      described_class[username: 'blah']
    }.to change { Entity::User.count }.by(1)

    Entity::User.destroy_all
    user = Entity::User.create!

    expect {
      described_class[username: 'blah2', entity_user_id: user.id]
    }.not_to change { Entity::User.count }
  end

  it 'creates an account when an id is not passed' do
    expect {
      described_class[username: 'blah']
    }.to change { OpenStax::Accounts::Account.count }.by(1)

    OpenStax::Accounts::Account.destroy_all
    account = OpenStax::Accounts::Account.create!(username: 'account',
                                                  openstax_uid: 'something')

    expect {
      described_class[account_id: account.id]
    }.not_to change { OpenStax::Accounts::Account.count }
  end
end
