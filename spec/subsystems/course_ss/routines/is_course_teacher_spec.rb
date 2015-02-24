require 'rails_helper'

describe CourseSs::IsCourseTeacher do

  context "when not a teacher of the given course" do
    let(:target_course)       { EntitySs::CreateCourse.call.outputs.course }
    let(:other_course)        { EntitySs::CreateCourse.call.outputs.course }
    let(:target_teacher_role) { EntitySs::CreateRole.call.outputs.role }
    let(:other_teacher_role)  { EntitySs::CreateRole.call.outputs.role }

    before(:each) do
      CourseSs::AddTeacher.call(course: other_course,  role: target_teacher_role)
      CourseSs::AddTeacher.call(course: target_course, role: other_teacher_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseSs::IsCourseTeacher.call(course: target_course, role: target_teacher_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_falsey
      end
    end
    context "multiple roles are given" do
      it "returns false" do
        other_role1 = EntitySs::CreateRole.call.outputs.role
        other_role2 = EntitySs::CreateRole.call.outputs.role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseSs::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_falsey
      end
    end
  end

  context "when a teacher of the given course" do
    let(:target_course)       { EntitySs::CreateCourse.call.outputs.course }
    let(:target_teacher_role) { EntitySs::CreateRole.call.outputs.role }

    before(:each) do
      CourseSs::AddTeacher.call(course: target_course, role: target_teacher_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseSs::IsCourseTeacher.call(course: target_course, role: target_teacher_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
    context "multiple roles are given" do
      it "returns false" do
        other_role1 = EntitySs::CreateRole.call.outputs.role
        other_role2 = EntitySs::CreateRole.call.outputs.role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseSs::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
  end

  context "invalid usage" do
    let(:course) { double(EntitySs::Course) }
    let(:role)   { double(EntitySs::Role) }
    let(:roles)  { [] }

    context "when both role: and roles: are given" do
      it "has errors" do
        result = CourseSs::IsCourseTeacher.call(course: course, role: role, roles: roles)
        expect(result.errors).to_not be_empty
        expect(result.errors.detect{|e| e.code == :invalid_usage}).to_not be_nil
      end
    end
    context "when neither role: nor roles: is given" do
      it "has errors" do
        result = CourseSs::IsCourseTeacher.call(course: course)
        expect(result.errors).to_not be_empty
        expect(result.errors.detect{|e| e.code == :invalid_usage}).to_not be_nil
      end
    end
  end

end
