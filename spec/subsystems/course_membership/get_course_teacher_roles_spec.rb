require 'rails_helper'

describe CourseMembership::GetCourseTeacherRoles do
  let(:target_course) { Entity::Course.create! }
  let(:course_period) { CreatePeriod[course: target_course] }

  let(:other_course)  { Entity::Course.create! }
  let(:other_period)  { CreatePeriod[course: other_course] }

  let!(:other_student_role) {
    other_role = Entity::Role.create!
    CourseMembership::AddStudent.call(
      period: other_period,
      role:   other_role
    )
    other_role
  }

  let!(:other_teacher_role) {
    other_role = Entity::Role.create!
    CourseMembership::AddTeacher.call(
      course: other_course,
      role:   other_role
    )
    other_role
  }

  context "when there are no roles for the target course" do
    it "returns an empty enumerable" do
      result = described_class.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.roles).to be_empty
    end
  end

  context "when there is one student role for the target course" do
    let!(:target_student_role) {
      target_role = Entity::Role.create!
      CourseMembership::AddStudent.call(
        period: course_period,
        role:   target_role
      )
      target_role
    }

    it "returns an empty enumerable" do
      result = described_class.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.roles).to be_empty
    end
  end

  context "when there is one teacher role for the target course" do
    let!(:target_teacher_role) {
      target_role = Entity::Role.create!
      CourseMembership::AddTeacher.call(
        course: target_course,
        role:   target_role
      )
      target_role
    }

    it "returns an enumerable containing that role" do
      result = described_class.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.roles.count).to eq(1)
      expect(result.outputs.roles).to include(target_teacher_role)
    end
  end

  context "when there are multiple teacher/student roles for the target course" do
    let!(:target_roles) {
      target_role1 = Entity::Role.create!
      CourseMembership::AddStudent.call(
        period: course_period,
        role:   target_role1
      )

      target_role2 = Entity::Role.create!
      CourseMembership::AddTeacher.call(
        course: target_course,
        role:   target_role2
      )

      target_role3 = Entity::Role.create!
      CourseMembership::AddStudent.call(
        period: course_period,
        role:   target_role3
      )
      [target_role2]
    }

    it "returns an enumerable containing only the teacher roles" do
      result = described_class.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.roles.count).to eq(target_roles.count)
      target_roles.each do |target_role|
        expect(result.outputs.roles).to include(target_role)
      end
    end
  end

end
