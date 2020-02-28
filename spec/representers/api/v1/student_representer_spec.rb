require 'rails_helper'

RSpec.describe Api::V1::StudentRepresenter, type: :representer do
  let(:user)    { FactoryBot.create(:user_profile) }
  let(:period)  { FactoryBot.create(:course_membership_period) }
  let(:course)  { period.course }
  let(:student) { AddUserAsPeriodStudent.call(period: period, user: user).outputs.student }
  let(:representation) { Api::V1::StudentRepresenter.new(student).as_json }

  it 'represents a student' do
    student.update_attributes(first_paid_at: 2.days.ago)

    expect(representation).to match(
      'id' => student.id.to_s,
      'uuid' => student.uuid,
      'period_id' => period.id.to_s,
      'role_id' => student.role.id.to_s,
      'first_name' => student.first_name,
      'last_name' => student.last_name,
      'name' => student.name,
      'is_active' => !student.dropped?,
      'is_paid' => false,
      'is_comped' => false,
      'payment_due_at' => be_kind_of(String),
      'first_paid_at' => be_kind_of(String),
      'is_refund_pending' => false,
      'is_refund_allowed' => false,
      'prompt_student_to_pay' => false
    )

    [:first_paid_at, :payment_due_at].each do |date_method|
      actual_value = Chronic.parse(representation[date_method.to_s])
      expected_value = student.send(date_method)
      expect(actual_value).to be_within(1.seconds).of(expected_value)
    end
  end

  context '#prompt_student_to_pay' do
    it 'needs global setting enabled to return true' do
      allow(Settings::Payments).to receive(:payments_enabled) { false }
      student.update_attributes(is_paid: true)
      course.update_attributes(is_preview: false, does_cost: true)
      expect(representation).to include('prompt_student_to_pay' => false)
    end

    it 'needs course to cost to return true' do
      allow(Settings::Payments).to receive(:payments_enabled) { true }
      student.update_attributes(is_paid: true)
      course.update_attributes(is_preview: false, does_cost: false)
      expect(representation).to include('prompt_student_to_pay' => false)
    end

    it 'needs course to not be preview to return true' do
      allow(Settings::Payments).to receive(:payments_enabled) { true }
      student.update_attributes(is_paid: true)
      course.update_attributes(is_preview: true, does_cost: true)
      expect(representation).to include('prompt_student_to_pay' => false)
    end

    it 'returns false is paid' do
      allow(Settings::Payments).to receive(:payments_enabled) { true }
      student.update_attributes(is_paid: true, is_comped: false)
      course.update_attributes(is_preview: false, does_cost: true)
      expect(representation).to include('prompt_student_to_pay' => false)
    end

    it 'returns false is comped' do
      allow(Settings::Payments).to receive(:payments_enabled) { true }
      student.update_attributes(is_paid: false, is_comped: true)
      course.update_attributes(is_preview: false, does_cost: true)
      expect(representation).to include('prompt_student_to_pay' => false)
    end
  end

end
