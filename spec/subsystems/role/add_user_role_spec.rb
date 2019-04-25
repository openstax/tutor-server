require 'rails_helper'

RSpec.describe Role::AddUserRole, type: :routine do
  context "when adding a new user role" do
    it "succeeds" do
      role = FactoryBot.create :entity_role
      user = FactoryBot.create :user

      result = nil
      expect {
        result = Role::AddUserRole.call(user: user, role: role)
      }.to change { Role::Models::RoleUser.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when adding an existing user role" do
    it "fails" do
      role = FactoryBot.create :entity_role
      user = FactoryBot.create :user

      result = nil
      expect {
        result = Role::AddUserRole.call(user: user, role: role)
      }.to change { Role::Models::RoleUser.count }.by(1)
      expect(result.errors).to be_empty

      expect {
        result = Role::AddUserRole.call(user: user, role: role)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
