require 'rails_helper'

RSpec.describe SchoolAccessPolicy do
  let!(:anon)           { AnonymousUser.instance }
  let!(:user)           { FactoryGirl.create(:user) }
  let!(:application)    { FactoryGirl.create(:doorkeeper_application) }
  let!(:school)         { FactoryGirl.build(:school) }
  let!(:school_manager) { FactoryGirl.create(:school_manager, school: school) }
  let!(:administrator)  { FactoryGirl.create(:administrator) }

  context 'index, read' do
    it 'cannot be accessed by anonymous users or applications' do
      expect(SchoolAccessPolicy.action_allowed?(:index, anon, School)).to eq false
    end

    it 'can be accessed by any authenticated user' do
      expect(SchoolAccessPolicy.action_allowed?(:index, application, School)).to eq true

      expect(SchoolAccessPolicy.action_allowed?(:index, user, School)).to eq true
    end
  end

  context 'create and destroy' do
    it 'cannot be accessed by anonymous users, applications, unrelated users or school managers' do
      expect(SchoolAccessPolicy.action_allowed?(
        :create, anon, school)).to eq false
      expect(SchoolAccessPolicy.action_allowed?(
        :destroy, anon, school)).to eq false

      expect(SchoolAccessPolicy.action_allowed?(
        :create, application, school)).to eq false
      expect(SchoolAccessPolicy.action_allowed?(
        :destroy, application, school)).to eq false

      expect(SchoolAccessPolicy.action_allowed?(
        :create, user, school)).to eq false
      expect(SchoolAccessPolicy.action_allowed?(
        :destroy, user, school)).to eq false

      expect(SchoolAccessPolicy.action_allowed?(
        :create, school_manager.user, school)).to eq false
      expect(SchoolAccessPolicy.action_allowed?(
        :destroy, school_manager.user, school)).to eq false
    end

    it 'can be accessed by administrators' do
      expect(SchoolAccessPolicy.action_allowed?(
        :create, administrator.user, school)).to eq true
      expect(SchoolAccessPolicy.action_allowed?(
        :destroy, administrator.user, school)).to eq true
    end
  end

  context 'update' do
    it 'cannot be accessed by anonymous users, applications or unrelated users' do
      expect(SchoolAccessPolicy.action_allowed?(:update, anon, school)).to eq false

      expect(SchoolAccessPolicy.action_allowed?(:update, application, school)).to eq false

      expect(SchoolAccessPolicy.action_allowed?(:update, user, school)).to eq false
    end

    it 'can be accessed by school managers and administrators' do
      expect(SchoolAccessPolicy.action_allowed?(
        :update, school_manager.user, school)).to eq true

      expect(SchoolAccessPolicy.action_allowed?(
        :update, administrator.user, school)).to eq true
    end
  end
end
