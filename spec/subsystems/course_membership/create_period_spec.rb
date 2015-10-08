require 'rails_helper'

RSpec.describe CourseMembership::CreatePeriod do
  it 'generates an enrollment_code' do
    allow(Babbler).to receive(:babble) { 'formidableWalrus' }

    course = CreateCourse[name: 'Great course']
    period = described_class[course: course, name: 'Cool period']

    expect(period.enrollment_code).to eq('formidableWalrus')
  end
end
