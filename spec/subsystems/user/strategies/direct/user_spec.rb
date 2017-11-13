require 'rails_helper'

RSpec.describe User::Strategies::Direct::User, type: :strategy do
  subject(:user) { described_class.new(FactoryBot.create(:user_profile)) }

  it 'uses a normal account' do
    expect(user.account).to be_kind_of(OpenStax::Accounts::Account)
  end

  it 'is not anonymous' do
    expect(user).not_to be_is_anonymous
  end

  it 'is human' do
    expect(user.is_human?).to be_truthy
  end

  it 'is not an application' do
    expect(user.is_application?).to be_falsy
  end
end
