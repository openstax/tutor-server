require 'rails_helper'

RSpec.describe CreateOrResetTeacherStudent, type: :routine do
  let(:user)   { FactoryBot.create :user_profile }
  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  context "when the given user has no teacher_student roles in the period" do
    it "creates and returns the user's new teacher_student role" do
      result = nil
      expect do
        result = described_class.call(user: user, period: period)
      end.to change { CourseMembership::Models::TeacherStudent.count }

      expect(result.errors).to be_empty
      new_role = result.outputs.role
      expect(new_role).not_to be_nil
      expect(new_role.role_type).to eq 'teacher_student'
      expect(new_role.teacher_student).to be_present
      expect(new_role.teacher_student).not_to be_deleted
    end
  end

  context "when the given user already has a teacher_student role in the period" do
    let!(:teacher_student_role) { described_class.call(user: user, period: period).outputs.role }
    let!(:teacher_student)      { teacher_student_role.teacher_student }

    it "deletes the previous role, creates and returns the user's new teacher_student role" do
      result = nil
      expect do
        result = described_class.call(user: user, period: period)
      end.to  change { CourseMembership::Models::TeacherStudent.count }
         .and change { teacher_student.reload.deleted? }

      expect(result.errors).to be_empty
      new_role = result.outputs.role
      expect(new_role).not_to be_nil
      expect(new_role.role_type).to eq 'teacher_student'
      expect(new_role.teacher_student).to be_present
      expect(new_role.teacher_student).not_to be_deleted
      expect(new_role).not_to eq teacher_student_role
    end
  end
end
