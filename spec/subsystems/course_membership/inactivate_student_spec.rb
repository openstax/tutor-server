require 'rails_helper'

describe CourseMembership::InactivateStudent, type: :routine do
  let!(:student) { FactoryGirl.create(:course_membership_student) }

  context "active student" do
    it "inactivates the student" do
      described_class[student: student]
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
