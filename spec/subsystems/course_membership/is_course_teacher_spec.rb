require 'rails_helper'

RSpec.describe CourseMembership::IsCourseTeacher do

  context "when not a teacher of the given course" do
    let(:target_course)       { FactoryBot.create :course_profile_course }
    let(:other_course)        { FactoryBot.create :course_profile_course }
    let(:target_teacher_role) { FactoryBot.create :entity_role }
    let(:other_teacher_role)  { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: other_course,  role: target_teacher_role)
      CourseMembership::AddTeacher.call(course: target_course, role: other_teacher_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseMembership::IsCourseTeacher.call(
          course: target_course, roles: target_teacher_role
        )
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to eq false
        expect(result.outputs.is_deleted).to eq false
      end
    end

    context "when multiple roles are given" do
      it "returns false" do
        other_role1 = FactoryBot.create :entity_role
        other_role2 = FactoryBot.create :entity_role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to eq false
        expect(result.outputs.is_deleted).to eq false
      end
    end

    context "when express called" do
      it "returns false" do
        is_course_teacher = CourseMembership::IsCourseTeacher[
          course: target_course, roles: target_teacher_role
        ]
        expect(is_course_teacher).to eq false
      end
    end
  end

  context "when a teacher of the given course" do
    let(:target_course)       { FactoryBot.create :course_profile_course }
    let(:target_teacher_role) { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddTeacher.call(course: target_course, role: target_teacher_role)
    end

    context "when a single role is given" do
      it "returns true" do
        result = CourseMembership::IsCourseTeacher.call(
          course: target_course, roles: target_teacher_role
        )
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to eq true
        expect(result.outputs.is_deleted).to eq false
      end
    end

    context "when multiple roles are given" do
      it "returns true" do
        other_role1 = FactoryBot.create :entity_role
        other_role2 = FactoryBot.create :entity_role
        roles = [target_teacher_role, other_role1, other_role2]

        result = CourseMembership::IsCourseTeacher.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to eq true
        expect(result.outputs.is_deleted).to eq false
      end
    end

    context "when teacher has been deleted" do
      before { target_teacher_role.teacher.destroy }

      context "when include_deleted_teachers is given" do
        it "returns true" do
          result = CourseMembership::IsCourseTeacher.call(
            course: target_course, roles: target_teacher_role, include_deleted_teachers: true
          )
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_teacher).to eq true
          expect(result.outputs.is_deleted).to eq true
        end
      end

      context "when include_deleted_teachers is not given" do
        it "returns false" do
          result = CourseMembership::IsCourseTeacher.call(
            course: target_course, roles: target_teacher_role
          )
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_teacher).to eq false
          expect(result.outputs.is_deleted).to eq false
        end
      end
    end

    context "when express called" do
      it "returns true" do
        is_course_teacher = CourseMembership::IsCourseTeacher[
          course: target_course, roles: target_teacher_role
        ]
        expect(is_course_teacher).to eq true
      end
    end
  end

end
