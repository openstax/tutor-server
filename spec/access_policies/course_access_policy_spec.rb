require 'rails_helper'

RSpec.describe CourseAccessPolicy do
  let!(:anon)           { AnonymousUser.instance }
  let!(:user)           { FactoryGirl.create(:user) }
  let!(:application)    { FactoryGirl.create(:doorkeeper_application) }
  let!(:course)         { FactoryGirl.build(:course) }
  let!(:course_manager) { FactoryGirl.create(:course_manager, course: course) }
  let!(:school_manager) { FactoryGirl.create(:school_manager, school: course.school) }
  let!(:administrator)  { FactoryGirl.create(:administrator) }

  context 'index, read' do
    it 'cannot be accessed by anonymous users' do
      expect(CourseAccessPolicy.action_allowed?(:index, anon, Course)).to eq false
    end

    it 'can be accessed by any authenticated user' do
      expect(CourseAccessPolicy.action_allowed?(:index, application, Course)).to eq true

      expect(CourseAccessPolicy.action_allowed?(:index, user, Course)).to eq true
    end
  end

  context 'create and destroy' do
    it 'cannot be accessed by anonymous users, applications, unrelated users and course managers' do
      expect(CourseAccessPolicy.action_allowed?(
        :create, anon, course)).to eq false
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, anon, course)).to eq false

      expect(CourseAccessPolicy.action_allowed?(
        :create, application, course)).to eq false
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, application, course)).to eq false

      expect(CourseAccessPolicy.action_allowed?(
        :create, user, course)).to eq false
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, user, course)).to eq false

      expect(CourseAccessPolicy.action_allowed?(
        :create, course_manager.user, course)).to eq false
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, course_manager.user, course)).to eq false
    end

    it 'can be accessed by school managers and administrators' do
      expect(CourseAccessPolicy.action_allowed?(
        :create, school_manager.user, course)).to eq true
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, school_manager.user, course)).to eq true

      expect(CourseAccessPolicy.action_allowed?(
        :create, administrator.user, course)).to eq true
      expect(CourseAccessPolicy.action_allowed?(
        :destroy, administrator.user, course)).to eq true
    end
  end

  context 'update' do
    it 'cannot be accessed by anonymous users, applications or unrelated users' do
      expect(CourseAccessPolicy.action_allowed?(:update, anon, course)).to eq false

      expect(CourseAccessPolicy.action_allowed?(:update, application, course)).to eq false

      expect(CourseAccessPolicy.action_allowed?(:update, user, course)).to eq false
    end

    it 'can be accessed by course managers, school managers and administrators' do
      expect(CourseAccessPolicy.action_allowed?(
        :update, course_manager.user, course)).to eq true

      expect(CourseAccessPolicy.action_allowed?(
        :update, school_manager.user, course)).to eq true

      expect(CourseAccessPolicy.action_allowed?(
        :update, administrator.user, course)).to eq true
    end
  end
end
