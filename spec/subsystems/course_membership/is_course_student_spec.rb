require 'rails_helper'

RSpec.describe CourseMembership::IsCourseStudent, type: :routine do

  context "when not a student of the given course" do
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:target_period) { FactoryBot.create :course_membership_period, course: target_course }
    let(:other_course)  { FactoryBot.create :course_profile_course }
    let(:other_period)  { FactoryBot.create :course_membership_period, course: other_course }

    let(:target_student_role) { FactoryBot.create :entity_role }
    let(:other_student_role)  { FactoryBot.create :entity_role }

    before(:each) do
      CourseMembership::AddStudent.call(period: other_period,  role: target_student_role)
      CourseMembership::AddStudent.call(period: target_period, role: other_student_role)
    end

    context "when a single role is given" do
      it "returns false" do
        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: target_student_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_student).to eq false
      end
    end
    context "multiple roles are given" do
      it "returns false" do
        other_role1 = FactoryBot.create :entity_role
        other_role2 = FactoryBot.create :entity_role
        roles = [target_student_role, other_role1, other_role2]

        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_student).to eq false
      end
    end
    context "when expressed called" do
      it "returns false" do
        is_course_student = CourseMembership::IsCourseStudent[
          course: target_course,
          roles: target_student_role
        ]
        expect(is_course_student).to eq false
      end
    end
  end

  context "when a student of the given course" do
    let(:target_course)       { FactoryBot.create :course_profile_course }
    let(:target_period)       { FactoryBot.create :course_membership_period,
                                                   course: target_course }
    let(:target_student_role) { FactoryBot.create :entity_role }
    let!(:student) { CourseMembership::AddStudent[period: target_period, role: target_student_role] }

    context "when a single role is given" do
      it "returns true" do
        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: target_student_role)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_student).to eq true
      end
    end
    context "multiple roles are given" do
      it "returns true" do
        other_role1 = FactoryBot.create :entity_role
        other_role2 = FactoryBot.create :entity_role
        roles = [target_student_role, other_role1, other_role2]

        result = CourseMembership::IsCourseStudent.call(course: target_course, roles: roles)
        expect(result.errors).to be_empty
        expect(result.outputs.is_archived).to eq false
        expect(result.outputs.is_course_student).to eq true
      end
    end
    context "when expressed called" do
      it "returns false" do
        is_course_student = CourseMembership::IsCourseStudent[
          course: target_course,
          roles: target_student_role
        ]
        expect(is_course_student).to eq true
      end
    end
    context "when period is archived" do
      before(:each) { target_period.destroy }

      it "returns is_archived" do
        result = CourseMembership::IsCourseStudent.call(
          course: target_course, roles: target_student_role, include_archived_periods: true
        )
        expect(result.outputs.is_archived).to eq true
      end
    end

    context "when student is dropped" do
      before(:each) do
        student.destroy
      end
      it "returns is_dropped" do
        result = CourseMembership::IsCourseStudent.call(
          course: target_course, roles: target_student_role, include_dropped_students: true
        )
        expect(result.outputs.is_archived).to eq false
        expect(result.outputs.is_dropped).to eq true
      end

    end

  end

end
