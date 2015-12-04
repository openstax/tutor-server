require 'rails_helper'

describe CourseMembership::InactivateStudent, type: :routine do
  let!(:student) { FactoryGirl.create(:course_membership_student) }
  let!(:course)  { student.course }

  context "active student" do
    it "inactivates but does not delete the given student" do
      result = nil
      expect {
        result = described_class.call(student: student)
      }.not_to change{ CourseMembership::Models::Student.count }
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student).not_to be_active
    end
  end

  context "inactive student" do
    before { student.inactivate.save! }

    it "returns an error" do
      result = described_class.call(student: student)
      expect(result.errors.first.code).to eq :already_inactive
      expect(student).not_to be_active
    end
  end
end
