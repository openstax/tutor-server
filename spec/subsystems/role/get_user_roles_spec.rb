require 'rails_helper'

describe Role::GetUserRoles, type: :routine do
  context "there are no roles for the given user" do
    it "returns an empty array" do
      target_user = FactoryGirl.create(:user)
      other_user = FactoryGirl.create(:user)

      role   = Entity::Role.create!

      Role::AddUserRole.call(user: other_user, role: role)

      result = Role::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.roles).to be_empty
    end
  end
  context "there is one role for the given user" do
    it "returns that role" do
      target_user = FactoryGirl.create(:user)
      target_role = Entity::Role.create!
      other_user = FactoryGirl.create(:user)
      other_role  = Entity::Role.create!

      Role::AddUserRole.call(user: target_user, role: target_role)
      Role::AddUserRole.call(user: other_user,  role: other_role)

      result = Role::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.roles.size).to eq(1)
      expect(result.roles).to include(target_role)
    end
  end
  context "there are multiple roles for the given user" do
    it "returns all user roles" do
      target_user = FactoryGirl.create(:user)
      target_role1 = Entity::Role.create!
      target_role2 = Entity::Role.create!

      other_user = FactoryGirl.create(:user)
      other_role = Entity::Role.create!

      Role::AddUserRole.call(user: target_user, role: target_role1)
      Role::AddUserRole.call(user: target_user, role: target_role2)
      Role::AddUserRole.call(user: other_user,  role: other_role)

      result = Role::GetUserRoles.call(target_user)

      expect(result.errors).to be_empty
      expect(result.roles.size).to eq(2)
      expect(result.roles).to include(target_role1)
      expect(result.roles).to include(target_role2)
    end

    xit "returns limited types when requested" do
      # implemente me
    end
  end
end
