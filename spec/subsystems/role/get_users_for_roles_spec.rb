require 'rails_helper'

describe Role::GetUsersForRoles, type: :routine do
  context "when there are no users for the given roles" do
    let(:role1) { Entity::Role.create! }
    let(:role2) { Entity::Role.create! }
    let(:roles) { [role1, role2] }

    it "returns an empty array" do
      result = Role::GetUsersForRoles.call(roles)
      expect(result.errors).to be_empty
      expect(result.users).to be_empty
    end
  end

  context "when there is one user for the given roles" do
    let(:target_user)  { FactoryGirl.create(:user) }
    let(:other_user)   { FactoryGirl.create(:user) }
    let(:target_role1) { Entity::Role.create! }
    let(:target_role2) { Entity::Role.create! }
    let(:other_role)   { Entity::Role.create! }
    let(:dummy_role)   { Entity::Role.create! }
    let(:roles)        { [target_role1, dummy_role, target_role2] }

    before(:each) do
      Role::AddUserRole.call(user: target_user, role: target_role1)
      Role::AddUserRole.call(user: target_user, role: target_role2)
      Role::AddUserRole.call(user: other_user,  role: other_role)
    end

    it "returns an array containing that user" do
      result = Role::GetUsersForRoles.call(roles)
      expect(result.errors).to be_empty
      expect(result.users.size).to eq(1)
      expect(result.users).to include(target_user)
    end
  end

  context "when there are multiple users for the given roles" do
    let(:target_user1) { FactoryGirl.create(:user) }
    let(:target_user2) { FactoryGirl.create(:user) }
    let(:other_user)   { FactoryGirl.create(:user) }
    let(:target_role1) { Entity::Role.create! }
    let(:target_role2) { Entity::Role.create! }
    let(:other_role)   { Entity::Role.create! }
    let(:dummy_role)   { Entity::Role.create! }
    let(:roles)        { [target_role1, dummy_role, target_role2] }

    before(:each) do
      Role::AddUserRole.call(user: target_user1, role: target_role1)
      Role::AddUserRole.call(user: target_user1, role: target_role2)
      Role::AddUserRole.call(user: target_user2, role: target_role1)
      Role::AddUserRole.call(user: other_user,  role: other_role)
    end

    it "returns an array containing that user" do
      result = Role::GetUsersForRoles.call(roles)
      expect(result.errors).to be_empty
      expect(result.users.size).to eq(2)
      expect(result.users).to include(target_user1)
      expect(result.users).to include(target_user2)
    end
  end

  context "when a single role is given" do
    xit "that role is treated like an array containing the role" do
    end
  end

end
