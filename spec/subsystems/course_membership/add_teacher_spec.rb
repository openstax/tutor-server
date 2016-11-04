require 'rails_helper'

RSpec.describe CourseMembership::AddTeacher do
  context "when adding a new teacher role to a course" do
    it "succeeds" do
      role   = FactoryGirl.create :entity_role
      course = FactoryGirl.create :course_profile_course

      result = nil
      expect {
        result = CourseMembership::AddTeacher.call(course: course, role: role)
      }.to change { CourseMembership::Models::Teacher.count }.by(1)
      expect(result.errors).to be_empty
    end
  end

  context "when adding a existing teacher role to a course" do
    it "fails" do
      role   = FactoryGirl.create :entity_role
      course = FactoryGirl.create :course_profile_course

      result = nil
      expect {
        result = CourseMembership::AddTeacher.call(course: course, role: role)
      }.to change { CourseMembership::Models::Teacher.count }.by(1)
      expect(result.errors).to be_empty

      expect {
        result = CourseMembership::AddTeacher.call(course: course, role: role)
      }.to_not change { CourseMembership::Models::Teacher.count }
      expect(result.errors).to_not be_empty
    end
  end
end
