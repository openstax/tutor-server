require 'rails_helper'

describe Role::CreateUserRole, type: :routine do
  it "creates and returns a new role for the given user" do
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    user = User::User.new(strategy: strategy)

    result = nil
    expect {
      result = Role::CreateUserRole.call(user)
    }.to change{Role::GetUserRoles.call(user).outputs.roles.count}.by(1)
    expect(result.errors).to be_empty
  end
end
