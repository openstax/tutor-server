require 'rails_helper'

RSpec.describe GetCourseTeacherUsers, type: :routine do

  context "when a course has no teachers" do
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:other_user)    { FactoryBot.create(:user) }

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
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:target_user)   { FactoryBot.create(:user) }
    let(:other_user)    { FactoryBot.create(:user) }

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
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:target_user1)  { FactoryBot.create(:user) }
    let(:target_user2)  { FactoryBot.create(:user) }
    let(:other_user)    { FactoryBot.create(:user) }

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
