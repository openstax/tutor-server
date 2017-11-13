require "rails_helper"

RSpec.describe 'Drop timing and refunds', type: :request, version: :v1 do
  let(:period)     { FactoryBot.create :course_membership_period }
  let(:user)       { FactoryBot.create :user }
  let(:student) do
    AddUserAsPeriodStudent[user: user, period: period, student_identifier: 'N0B0DY'].student
  end

  context "when dropped within the 14 day refund period" do
    it "refunds the student, and they can re-enroll and pay again" do
      pay_for(student)
      expect(student).to be_is_paid
      drop(student)
      expect(student).not_to be_is_paid
      enroll(student)
      expect(student).not_to be_is_paid
      pay_for(student)
      expect(student).to be_is_paid
    end
  end

  context "when dropped after the 14 day refund period" do
    it "does not refund the student, and the student is paid if re-enrolls" do
      pay_for(student)
      expect(student).to be_is_paid
      Timecop.travel(Time.now + 14.days) do
        drop(student)
        expect(student).to be_is_paid
        enroll(student)
        expect(student).to be_is_paid
      end
    end
  end

  # The `UpdatePaymentStatus` calls simulate the behavior of real Payments, which
  # calls back to Tutor `/api/purchases/uuid/check` which calls `UpdatePaymentStatus`

  def pay_for(student)
    OpenStax::Payments::Api.client.fake_pay(product_instance_uuid: student.uuid)
    UpdatePaymentStatus.call(uuid: student.uuid)
    student.reload
  end

  def drop(student)
    CourseMembership::InactivateStudent[student: student]
    UpdatePaymentStatus.call(uuid: student.uuid)
    student.reload
  end

  def enroll(student)
    CourseMembership::ActivateStudent[student: student]
    student.reload
  end

end
