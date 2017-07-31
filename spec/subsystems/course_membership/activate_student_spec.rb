require 'rails_helper'

RSpec.describe CourseMembership::ActivateStudent, type: :routine do
  let(:course)  { FactoryGirl.create :course_profile_course }
  let(:period)  { FactoryGirl.create :course_membership_period, course: course }
  let(:user)    { FactoryGirl.create(:user) }
  let(:student) { AddUserAsPeriodStudent.call(user: user, period: period).outputs.student }

  context "inactive student" do
    before { student.destroy }

    it "activates the student" do
      result = nil
      expect {
        result = described_class.call(student: student)
      }.to change{ student.reload.dropped? }.from(true).to(false)
      expect(result.errors).to be_empty

      expect(student.course).to eq course
    end
  end

  context "active student" do
    it "returns an error" do
      result = described_class.call(student: student)
      expect(result.errors.first.code).to eq :already_active
    end
  end
end
