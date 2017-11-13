require 'rails_helper'

RSpec.describe CourseMembership::CreatePeriod do
  it 'generates an enrollment_code' do
    allow(SecureRandom).to receive(:random_number) { 1 }

    course = FactoryBot.create :course_profile_course
    period = described_class[course: course, name: 'Cool period']

    expect(period.enrollment_code).to eq('000001')
  end
end
