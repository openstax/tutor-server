require 'rails_helper'

describe CourseMembership::ActivateStudent, type: :routine do
  let!(:student) { FactoryGirl.create(:course_membership_student) }

  context "inactive student" do
    before { student.inactivate.save! }

    it "activates the student" do
      described_class[student: student]
      expect(student).to be_active
    end
  end

  context "active student" do
    it "returns an error" do
      result = described_class.call(student: student)
      expect(result.errors.first.code).to eq :already_active
      expect(student).to be_active
    end
  end
end
