require 'rails_helper'

describe RoleSs::AddUserRole do
  context "when adding a new user role" do
    it "succeeds" do
      role = EntitySs::CreateNewRole.call.outputs.role
      user = EntitySs::CreateNewUser.call.outputs.user

      result = nil
      expect {
        result = RoleSs::AddUserRole.call(user: user, role: role)
      }.to change{RoleSs::UserRoleMap.count}.by(1)
      expect(result.errors).to be_empty
    end
  end
  context "when adding a existing user role" do
    it "fails" do
      role   = EntitySs::CreateNewRole.call.outputs.role
      user = EntitySs::CreateNewUser.call.outputs.user

      result = nil
      expect {
        result = RoleSs::AddUserRole.call(user: user, role: role)
      }.to change{RoleSs::UserRoleMap.count}.by(1)
      expect(result.errors).to be_empty

      expect {
        result = RoleSs::AddUserRole.call(user: user, role: role)
      }.to_not change{RoleSs::UserRoleMap.count}
      expect(result.errors).to_not be_empty
    end
  end
end
