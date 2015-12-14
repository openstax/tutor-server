require 'rails_helper'

RSpec.describe User::MakeAdministrator, type: :routine do
  it 'makes a user an administrator' do
    user = FactoryGirl.create(:user)

    expect(user.is_admin?).to be false

    described_class.call(user: user)
    user.to_model.reload

    expect(user.is_admin?).to be true
  end
end
