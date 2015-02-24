require 'rails_helper'

describe RoleSs::GetUserRoles do
  context "there are no roles for the given user" do
    it "returns an empty array" do
      target_user = EntitySs::CreateUser.call.outputs.user
      other_user  = EntitySs::CreateUser.call.outputs.user
      role        = EntitySs::CreateRole.call.outputs.role

      RoleSs::AddUserRole.call(user: other_user, role: role)

      result = RoleSs::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.outputs.roles).to be_empty
    end
  end
  context "there is one role for the given user" do
    it "returns that role" do
      target_user = EntitySs::CreateUser.call.outputs.user
      target_role = EntitySs::CreateRole.call.outputs.role

      other_user  = EntitySs::CreateUser.call.outputs.user
      other_role  = EntitySs::CreateRole.call.outputs.role

      RoleSs::AddUserRole.call(user: target_user, role: target_role)
      RoleSs::AddUserRole.call(user: other_user,  role: other_role)

      result = RoleSs::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.outputs.roles.size).to eq(1)
      expect(result.outputs.roles).to include(target_role)
    end
  end
  context "there are multiple roles for the given user" do
    it "returns all user roles" do
      target_user  = EntitySs::CreateUser.call.outputs.user
      target_role1 = EntitySs::CreateRole.call.outputs.role
      target_role2 = EntitySs::CreateRole.call.outputs.role

      other_user   = EntitySs::CreateUser.call.outputs.user
      other_role   = EntitySs::CreateRole.call.outputs.role

      RoleSs::AddUserRole.call(user: target_user, role: target_role1)
      RoleSs::AddUserRole.call(user: target_user, role: target_role2)
      RoleSs::AddUserRole.call(user: other_user,  role: other_role)

      result = RoleSs::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.outputs.roles.size).to eq(2)
      expect(result.outputs.roles).to include(target_role1)
      expect(result.outputs.roles).to include(target_role2)
    end
  end
end
