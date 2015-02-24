require 'rails_helper'

describe CourseSs::AddStudent do
  context "when adding a new student role to a course" do
    it "succeeds" do
      role   = EntitySs::CreateNewRole.call.outputs.role
      course = EntitySs::CreateNewCourse.call.outputs.course

      result = nil
      expect {
        result = CourseSs::AddStudent.call(course: course, role: role)
      }.to change{CourseSs::StudentRoleMap.count}.by(1)
      expect(result.errors).to be_empty
    end
  end
  context "when adding a existing student role to a course" do
    it "fails" do
      role   = EntitySs::CreateNewRole.call.outputs.role
      course = EntitySs::CreateNewCourse.call.outputs.course

      result = nil
      expect {
        result = CourseSs::AddStudent.call(course: course, role: role)
      }.to change{CourseSs::StudentRoleMap.count}.by(1)
      expect(result.errors).to be_empty

      expect {
        result = CourseSs::AddStudent.call(course: course, role: role)
      }.to_not change{CourseSs::StudentRoleMap.count}
      expect(result.errors).to_not be_empty
    end
  end
end
