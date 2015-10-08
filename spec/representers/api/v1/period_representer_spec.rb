require 'rails_helper'

RSpec.describe Api::V1::PeriodRepresenter, type: :representer do
  it 'includes the enrollment code' do
    allow(Babbler).to receive(:babble) { 'awesome programmer' }

    course = CreateCourse[name: 'Course']
    period = CreatePeriod[course: course, name: 'Period I']

    repped = described_class.new(period).to_hash

    expect(repped['enrollment_code']).to eq('awesome programmer')
  end
end
