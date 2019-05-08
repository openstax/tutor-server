require 'rails_helper'

RSpec.describe CourseMembership::AddTeacherStudent, type: :routine do
  let(:role)     { FactoryBot.create :entity_role, role_type: :student }
  let(:course)   { FactoryBot.create :course_profile_course }
  let(:period_1) { FactoryBot.create :course_membership_period, course: course }
  let(:period_2) { FactoryBot.create :course_membership_period, course: course }

  context "when adding a new teacher_student role to a period" do
    it "succeeds" do
      result = nil
      expect do
        result = described_class.call(period: period_1, role: role)
      end.to change{ CourseMembership::Models::TeacherStudent.count }.by(1)
      expect(result.errors).to be_empty
      expect(course.reload.is_access_switchable).to eq true
    end
  end

  context "when adding an existing teacher_student role to a course" do
    it "fails" do
      result = nil
      expect do
        result = described_class.call(period: period_1, role: role)
      end.to change{ CourseMembership::Models::TeacherStudent.count }.by(1)
      expect(result.errors).to be_empty
      teacher_student = CourseMembership::Models::TeacherStudent.order(:created_at).last
      expect(teacher_student.course).to eq course
      expect(teacher_student.period.id).to eq period_1.id

      expect do
        result = described_class.call(period: period_2, role: role)
      end.to_not change{ CourseMembership::Models::TeacherStudent.count }
      expect(result.errors).to_not be_empty
      expect(teacher_student.reload.course).to eq course
      expect(teacher_student.period.id).to eq period_1.id
    end
  end

end
