require 'rails_helper'

RSpec.describe Settings, type: :lib do
  it 'can store editable application settings' do
    expect(Settings.timecop_time).to be_nil

    t = Time.now
    Settings.timecop_time = t
    expect(Settings.timecop_time).to eq t

    Settings.timecop_time = nil
    expect(Settings.timecop_time).to be_nil
  end
end
