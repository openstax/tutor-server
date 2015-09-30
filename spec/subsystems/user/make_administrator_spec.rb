require 'rails_helper'

RSpec.describe User::MakeAdministrator, type: :routine do
  it 'makes a user an administrator' do
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    user = User::User.new(strategy: strategy)

    expect(user.is_admin?).to be false

    described_class[user: user]
    profile.reload

    expect(user.is_admin?).to be true
  end
end
