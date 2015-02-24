require 'rails_helper'

describe RoleSs::CreateUserRole do
  it "creates and returns a new role for the given user" do
    user = EntitySs::CreateUser.call.outputs.user

    result = nil
    expect {
      result = RoleSs::CreateUserRole.call(user)
    }.to change{RoleSs::GetUserRoles.call(user).outputs.roles.count}.by(1)
    expect(result.errors).to be_empty
  end
end
