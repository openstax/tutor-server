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
      expect(result.outputs.roles).to be_empty
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
      expect(result.outputs.roles.size).to eq(1)
      expect(result.outputs.roles).to include(target_role)
    end
  end
  context "there are multiple roles for the given user" do
    let(:target_user){ FactoryGirl.create(:user) }
    let(:target_role1){ Entity::Role.create!(role_type: :student) }
    let(:target_role2){ Entity::Role.create!(role_type: :teacher) }

    let(:other_user){ FactoryGirl.create(:user) }
    let(:other_role){ Entity::Role.create! }

    let(:target_course) { Entity::Course.create! }
    let(:target_period) { CreatePeriod[course: target_course] }

    it "returns all user roles" do
      Role::AddUserRole.call(user: target_user, role: target_role1)
      Role::AddUserRole.call(user: target_user, role: target_role2)
      Role::AddUserRole.call(user: other_user,  role: other_role)
      result = Role::GetUserRoles.call(target_user)
      expect(result.errors).to be_empty
      expect(result.outputs.roles.size).to eq(2)
      expect(result.outputs.roles).to include(target_role1)
      expect(result.outputs.roles).to include(target_role2)
    end

    it "returns only type :student when requested" do
      Role::AddUserRole.call(user: target_user, role: target_role1)
      Role::AddUserRole.call(user: target_user, role: target_role2)

      AddUserAsPeriodStudent[period: target_period, user: target_user]
      # Manipulate the roles to set target_role2 to be type :student, but without an actual student linked
      target_role2.update_attributes!(role_type: :student)
      result = Role::GetUserRoles.call(target_user, :student)
      expect(result.errors).to be_empty
      expect(result.outputs.roles.size).to eq(1)
    end

    it "returns only type :teacher when requested" do
      Role::AddUserRole.call(user: target_user, role: target_role1)
      Role::AddUserRole.call(user: target_user, role: target_role2)

      CourseMembership::AddTeacher[course: target_course, role: target_role2]

      target_role1.update_attributes!(role_type: :teacher)

      result = Role::GetUserRoles.call(target_user, :teacher)
      expect(result.errors).to be_empty
      expect(result.outputs.roles.size).to eq(1)
    end

  end
end
