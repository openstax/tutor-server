require 'rails_helper'

describe CourseMembership::AddStudent do
  context "when adding a new student role to a course" do
    it "succeeds" do
      role   = Entity::CreateRole.call.outputs.role
      course = Entity::CreateCourse.call.outputs.course

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role)
      }.to change{CourseMembership::Models::Student.count}.by(1)
      expect(result.errors).to be_empty
    end
  end
  context "when adding a existing student role to a course" do
    it "fails" do
      role   = Entity::CreateRole.call.outputs.role
      course = Entity::CreateCourse.call.outputs.course

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role)
      }.to change{CourseMembership::Models::Student.count}.by(1)
      expect(result.errors).to be_empty

      expect {
        result = CourseMembership::AddStudent.call(course: course, role: role)
      }.to_not change{CourseMembership::Models::Student.count}
      expect(result.errors).to_not be_empty
    end
  end
end
