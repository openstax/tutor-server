require 'rails_helper'

RSpec.describe Settings, type: :lib do
  it 'can store editable application settings' do
    expect(Settings.timecop_offset).to be_nil

    Settings.timecop_offset = 1.hour
    expect(Settings.timecop_offset).to eq 1.hour

    Settings.timecop_offset = nil
    expect(Settings.timecop_offset).to be_nil
  end
end
