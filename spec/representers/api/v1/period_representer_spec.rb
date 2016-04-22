require 'rails_helper'

RSpec.describe Api::V1::PeriodRepresenter, type: :representer do
  let(:course) { CreateCourse[name: 'Course'] }
  let(:period) { CreatePeriod[course: course, name: 'Period I'] }
  subject(:represented) { described_class.new(period).to_hash }

  it 'includes the enrollment code' do
    allow(Babbler).to receive(:babble) { 'awesome programmer' }

    expect(represented['enrollment_code']).to eq('awesome programmer')
  end

  it 'includes the default open time' do
    period.to_model.default_open_time = Time.new(2016, 4, 20, 16, 43, 9)
    expect(represented['default_open_time']).to eq('16:43')
  end

  it 'includes the default due time' do
    period.to_model.default_due_time = Time.new(2017, 4, 20, 16, 44, 9)
    expect(represented['default_due_time']).to eq('16:44')
  end
end
