require 'rails_helper'

RSpec.describe CourseMembership::InactivateStudent, type: :routine do
  let(:student)  { FactoryGirl.create(:course_membership_student) }
  let!(:course)  { student.course }

  context "active student" do
    it "inactivates but does not delete the given student" do
      expect(RefundPayment).to receive(:perform_later).with(uuid: student.uuid)

      result = nil
      expect {
        result = described_class.call(student: student)
      }.to change{ CourseMembership::Models::Student.count }.by(-1)
      expect(result.errors).to be_empty

      expect(student.reload.course).to eq course
      expect(student).to be_persisted
      expect(student).to be_deleted

    end
  end

  context "inactive student" do
    before { student.destroy }

    it "returns an error" do
      result = described_class.call(student: student)
      expect(result.errors.first.code).to eq :already_inactive
      expect(student).to be_persisted
      expect(student).to be_deleted
    end
  end
end
