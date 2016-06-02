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
    period.to_model.default_open_time = '16:43'
    expect(represented['default_open_time']).to eq('16:43')
  end

  it 'includes the default due time' do
    period.to_model.default_due_time = '16:44'
    expect(represented['default_due_time']).to eq('16:44')
  end

  it 'includes is_archived: false if the period has not been archived' do
    expect(represented['is_archived']).to eq false
  end

  it 'includes is_archived: false if the period has been archived' do
    period.to_model.destroy!
    expect(represented['is_archived']).to eq true
  end

  it 'includes is_archived: false if the period has been restored' do
    period.to_model.destroy!
    period.to_model.restore!(recursive: true)
    expect(represented['is_archived']).to eq false
  end
end
