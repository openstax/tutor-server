require 'rails_helper'

describe Role::CreateUserRole, type: :routine do
  it "creates and returns a new role for the given user" do
    user = FactoryGirl.create(:user)

    result = nil
    expect {
      result = Role::CreateUserRole.call(user)
    }.to change{Role::GetUserRoles.call(user).roles.count}.by(1)
    expect(result.errors).to be_empty
  end
end
