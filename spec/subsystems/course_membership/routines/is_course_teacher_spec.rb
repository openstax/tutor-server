require 'rails_helper'

describe CourseMembership::IsCourseTeacher do

  context "when not a teacher of the given course" do
    let(:target_course)       { Entity::CreateCourse.call.outputs.course }
    let(:other_course)        { Entity::CreateCourse.call.outputs.course }
    let(:target_teacher_role) { Entity::CreateRole.call.outputs.role }
    let(:other_teacher_role)  { Entity::CreateRole.call.outputs.role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: other_course,  role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: other_teacher_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: target_teacher_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_falsey
      end
    end
    context "multiple roles are given" do
      it "returns false" do
        other_role1 = Entity::CreateRole.call.outputs.role
        other_role2 = Entity::CreateRole.call.outputs.role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_falsey
      end
    end
  end

  context "when a teacher of the given course" do
    let(:target_course)       { Entity::CreateCourse.call.outputs.course }
    let(:target_teacher_role) { Entity::CreateRole.call.outputs.role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_teacher_role)
    end

    context "when a single role is given" do
      it "returns true" do
        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: target_teacher_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
    context "multiple roles are given" do
      it "returns true" do
        other_role1 = Entity::CreateRole.call.outputs.role
        other_role2 = Entity::CreateRole.call.outputs.role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
  end

end
