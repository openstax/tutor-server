require 'rails_helper'

describe CourseMembership::ActivateStudent, type: :routine do
  let!(:course)  { CreateCourse[name: "Physics"] }
  let!(:period)  { CreatePeriod[course: course, name: "1st"] }
  let!(:user)    { FactoryGirl.create(:user) }
  let!(:student) { AddUserAsPeriodStudent.call(user: user, period: period).outputs.student }

  context "inactive student" do
    before { student.destroy }

    it "activates the student" do
      result = nil
      expect {
        result = described_class.call(student: student)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student).to be_persisted
      expect(student).not_to be_deleted
    end
  end

  context "active student" do
    it "returns an error" do
      result = described_class.call(student: student)
      expect(result.errors.first.code).to eq :already_active
      expect(student).to be_persisted
      expect(student).not_to be_deleted
    end
  end
end
