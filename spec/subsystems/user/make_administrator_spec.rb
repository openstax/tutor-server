require 'rails_helper'

RSpec.describe User::MakeAdministrator, type: :routine do
  it 'makes a user an administrator' do
    user = FactoryBot.create(:user_profile)

    expect(user.is_admin?).to be false

    described_class[user: user]
    user.reload

    expect(user.is_admin?).to be true
  end
end
