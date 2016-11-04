require 'rails_helper'

RSpec.describe MoveStudent, type: :routine do
  context "when moving an existing student role to another period in the same course" do
    it "succeeds" do
      role = FactoryGirl.create :entity_role
      course = FactoryGirl.create :course_profile_course
      period_1 = FactoryGirl.create :course_membership_period, course: course
      period_2 = FactoryGirl.create :course_membership_period, course: course
      student = CourseMembership::AddStudent[period: period_1, role: role]

      result = nil
      expect {
        result = MoveStudent.call(period: period_2, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_2.id

      expect {
        result = MoveStudent.call(period: period_1, student: student)
      }.to change{ CourseMembership::Models::Enrollment.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_1.id
    end
  end

  context "when adding an existing student role to another period in a different course" do
    it "fails" do
      role = FactoryGirl.create :entity_role
      course_1 = FactoryGirl.create :course_profile_course
      course_2 = FactoryGirl.create :course_profile_course
      period_1 = FactoryGirl.create :course_membership_period, course: course_1
      period_2 = FactoryGirl.create :course_membership_period, course: course_2
      student = CourseMembership::AddStudent[period: period_1, role: role]

      result = nil
      expect {
        result = MoveStudent.call(period: period_2, student: student)
      }.not_to change{ CourseMembership::Models::Enrollment.count }
      expect(result.errors).not_to be_empty

      expect(student.reload.course).to eq course_1
      expect(student.period.id).to eq period_1.id
    end
  end
end
