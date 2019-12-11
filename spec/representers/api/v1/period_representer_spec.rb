require 'rails_helper'

RSpec.describe Api::V1::PeriodRepresenter, type: :representer do
  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  def represented
    described_class.new(period).to_hash
  end

  it 'includes the enrollment code' do
    allow(SecureRandom).to receive(:random_number) { 123456 }

    expect(represented['enrollment_code']).to eq('123456')
  end

  it 'includes is_archived: false if the period has not been archived' do
    expect(represented['is_archived']).to eq false
  end

  it 'includes is_archived: false if the period has been archived' do
    period.destroy!
    expect(represented['is_archived']).to eq true
  end

  it 'includes is_archived: false if the period has been restored' do
    period.destroy!
    period.restore!
    expect(represented['is_archived']).to eq false
  end

  it 'includes student count' do
    student = AddUserAsPeriodStudent.call(
      period: period, user: FactoryBot.create(:user_profile)
    ).outputs.student
    expect(represented['num_enrolled_students']).to eq 1

    CourseMembership::InactivateStudent.call(student: student)
    expect(represented['num_enrolled_students']).to eq 0
  end
end
