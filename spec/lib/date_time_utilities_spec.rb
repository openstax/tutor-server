require 'rails_helper'

RSpec.describe DateTimeUtilities do
  it 'converts times to a tutor API friendly string' do
    Timecop.freeze('Aug 14, 2015 9:07 PM CST') do
      formatted_time = described_class.to_api_s(Time.current)
      expect(formatted_time).to eq('2015-08-15T03:07:00.000Z')
    end
  end

  it 'parses tutor API friendly time strings' do
    Timecop.freeze('Aug 14, 2015 9:07 PM CST') do
      parsed_time = described_class.from_api_s('2015-08-15T03:07:00.000Z')
      expect(parsed_time).to eq(Time.current)
    end
  end
end
