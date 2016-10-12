require 'rails_helper'

RSpec.describe CourseMembership::GetCourseRoles do
  let(:target_course) { FactoryGirl.create :entity_course }
  let(:target_period) { FactoryGirl.create :course_membership_period, course: target_course }

  let(:other_course) { FactoryGirl.create :entity_course }
  let(:other_period) { FactoryGirl.create :course_membership_period, course: other_course }

  let!(:other_student_role) {
    other_role = FactoryGirl.create :entity_role
    CourseMembership::AddStudent.call(
      period: other_period,
      role:   other_role
    )
    other_role
  }

  let!(:other_teacher_role) {
    other_role = FactoryGirl.create :entity_role
    CourseMembership::AddTeacher.call(
      course: other_course,
      role:   other_role
    )
    other_role
  }

  context "when an invalid :type is used" do
    let(:types) { :bogus_type }
    let!(:student_role) {
      target_role = FactoryGirl.create :entity_role
      CourseMembership::AddStudent.call(
        period: target_period,
        role:   target_role
      )
      target_role
    }
    let!(:teacher_role) {
      target_role = FactoryGirl.create :entity_role
      CourseMembership::AddTeacher.call(
        course: target_course,
        role:   target_role
      )
      target_role
    }

    it "returns an empty enumerable" do
      result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
      expect(result.errors).to be_empty
      expect(result.outputs.roles).to be_empty
    end
  end

  context "when types: :any" do
    let(:types) { :any }

    context "and there are no roles for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one student role for the target course" do
      let!(:target_student_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role
        )
        target_role
      }

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_student_role)
      end
    end

    context "and there is one teacher role for the target course" do
      let!(:target_teacher_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role
        )
        target_role
      }

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_teacher_role)
      end
    end

    context "and there are multiple teacher/student roles for the target course" do
      let!(:target_roles) {
        target_role1 = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role1
        )

        target_role2 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role2
        )

        target_role3 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role3
        )
        [target_role1, target_role2, target_role3]
      }

      it "returns an enumerable containing those roles" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(target_roles.count)
        target_roles.each do |target_role|
          expect(result.outputs.roles).to include(target_role)
        end
      end
    end
  end

  context "when types: :teacher" do
    let(:types) { :teacher }

    context "and there are no roles for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one student role for the target course" do
      let!(:target_student_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role
        )
        target_role
      }

      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one teacher role for the target course" do
      let!(:target_teacher_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role
        )
        target_role
      }

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_teacher_role)
      end
    end

    context "and there are multiple teacher/student roles for the target course" do
      let!(:target_roles) {
        target_role1 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role1
        )

        target_role2 = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role2
        )

        target_role3 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role3
        )
        [target_role2]
      }

      it "returns an enumerable containing only the teacher roles" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(target_roles.count)
        target_roles.each do |target_role|
          expect(result.outputs.roles).to include(target_role)
        end
      end
    end
  end

  context "when types: :student" do
    let(:types)         { :student }
    let(:target_course) { FactoryGirl.create :entity_course }
    let(:target_period) { FactoryGirl.create :course_membership_period, course: target_course }

    context "and there are no roles for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one student role for the target course" do
      let!(:target_student_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role
        )
        target_role
      }

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_student_role)
      end
    end

    context "and there is one teacher role for the target course" do
      let!(:target_teacher_role) {
        target_role = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role
        )
        target_role
      }

      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there are multiple teacher/student roles for the target course" do
      let!(:target_roles) {
        target_role1 = FactoryGirl.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role1
        )

        target_role2 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role2
        )

        target_role3 = FactoryGirl.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role3
        )
        [target_role2, target_role3]
      }

      it "returns an enumerable containing only the student roles" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(target_roles.count)
        target_roles.each do |target_role|
          expect(result.outputs.roles).to include(target_role)
        end
      end
    end
  end

end
