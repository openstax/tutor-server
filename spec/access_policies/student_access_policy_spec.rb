require 'rails_helper'

RSpec.describe StudentAccessPolicy do
  let!(:anon)           { AnonymousUser.instance }
  let!(:user)           { FactoryGirl.create(:user) }
  let!(:application)    { FactoryGirl.create(:doorkeeper_application) }
  let!(:klass)          { FactoryGirl.create(:klass) }
  let!(:student)        { FactoryGirl.build(:student, klass: klass) }
  let!(:educator)       { FactoryGirl.create(:educator, klass: klass) }
  let!(:course_manager) { FactoryGirl.create(:course_manager, course: klass.course) }
  let!(:school_manager) { FactoryGirl.create(:school_manager, school: klass.school) }
  let!(:administrator)  { FactoryGirl.create(:administrator) }

  context 'index' do
    it 'cannot be accessed by anonymous users or applications' do
      expect(StudentAccessPolicy.action_allowed?(:index, anon, Student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(:index, application, Student)).to eq false
    end

    it 'can be accessed by human users' do
      expect(StudentAccessPolicy.action_allowed?(:index, user, Student)).to eq true
    end
  end

  context 'read and destroy' do
    it 'cannot be accessed by anonymous users, applications or unrelated users' do
      expect(StudentAccessPolicy.action_allowed?(:read, anon, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(:destroy, anon, student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(:read, application, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(:destroy, application, student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(:read, user, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(:destroy, user, student)).to eq false
    end

    it 'can be accessed by the student himself, educators, course managers, school managers and administrators' do
      expect(StudentAccessPolicy.action_allowed?(
        :read, student.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :destroy, student.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :read, educator.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :destroy, educator.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :read, course_manager.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :destroy, course_manager.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :read, school_manager.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :destroy, school_manager.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :read, administrator.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :destroy, administrator.user, student)).to eq true
    end
  end

  context 'create and update' do
    it 'cannot be accessed by anonymous users, applications, unrelated users or the student himself' do
      expect(StudentAccessPolicy.action_allowed?(
        :create, anon, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(
        :update, anon, student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(
        :create, application, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(
        :update, application, student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(
        :create, user, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(
        :update, user, student)).to eq false

      expect(StudentAccessPolicy.action_allowed?(
        :create, student.user, student)).to eq false
      expect(StudentAccessPolicy.action_allowed?(
        :update, student.user, student)).to eq false
    end

    it 'can be accessed by educators, course managers, school managers and administrators' do
      expect(StudentAccessPolicy.action_allowed?(
        :create, educator.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :update, educator.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :create, course_manager.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :update, course_manager.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :create, school_manager.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :update, school_manager.user, student)).to eq true

      expect(StudentAccessPolicy.action_allowed?(
        :create, administrator.user, student)).to eq true
      expect(StudentAccessPolicy.action_allowed?(
        :update, administrator.user, student)).to eq true
    end
  end
end
