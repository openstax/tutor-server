require 'rails_helper'

describe GetCourseTeacherUsers, type: :routine do

  context "when a course has no teachers" do
    let(:target_course) { CreateCourse[name: 'target'] }
    let(:other_course)  { CreateCourse[name: 'other'] }
    let(:other_user)    {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }

    before(:each) do
      result = AddUserAsCourseTeacher.call(course: other_course, user: other_user)
      expect(result.errors).to be_empty
    end

    it "should return an empty array" do
      result = GetCourseTeacherUsers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers).to be_empty
    end
  end

  context "when a course has one teacher" do
    let(:target_course) { CreateCourse[name: 'target 2'] }
    let(:other_course)  { CreateCourse[name: 'other 2'] }
    let(:target_user)   {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let(:other_user)    {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }

    before(:each) do
      result = AddUserAsCourseTeacher.call(course: other_course, user: other_user)
      expect(result.errors).to be_empty
      result = AddUserAsCourseTeacher.call(course: target_course, user: target_user)
      expect(result.errors).to be_empty
    end

    it "should return an array containing that teacher" do
      result = GetCourseTeacherUsers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers.size).to eq(1)
      expect(result.outputs.teachers).to include(target_user)
    end
  end

  context "when a course has multiple teachers" do
    let(:target_course) { CreateCourse[name: 'target 3'] }
    let(:other_course)  { CreateCourse[name: 'other 3'] }
    let(:target_user1)  {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let(:target_user2)  {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }
    let(:other_user)    {
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy)
    }

    before(:each) do
      result = AddUserAsCourseTeacher.call(course: other_course, user: other_user)
      expect(result.errors).to be_empty
      result = AddUserAsCourseTeacher.call(course: target_course, user: target_user1)
      expect(result.errors).to be_empty
      result = AddUserAsCourseTeacher.call(course: target_course, user: target_user2)
      expect(result.errors).to be_empty
    end
    it "should return an array containing those teachers" do
      result = GetCourseTeacherUsers.call(target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.teachers.size).to eq(2)
      expect(result.outputs.teachers).to include(target_user1)
      expect(result.outputs.teachers).to include(target_user2)
    end
  end

end
