require 'rails_helper'

RSpec.describe Settings, type: :lib do
  it 'can store editable application settings' do
    expect(Settings::Timecop.offset).to be_nil

    Settings::Timecop.offset = 1.hour
    expect(Settings::Timecop.offset).to eq 1.hour

    Settings::Timecop.offset = nil
    expect(Settings::Timecop.offset).to be_nil
  end
end
