require 'rails_helper'

RSpec.describe Settings::Timecop, type: :lib do
  it 'can store the timecop offset' do
    expect(described_class.offset).to be_nil

    described_class.offset = 1.hour
    expect(described_class.offset).to eq 1.hour

    described_class.offset = nil
    expect(described_class.offset).to be_nil
  end
end
