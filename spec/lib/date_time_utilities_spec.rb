require 'rails_helper'

RSpec.describe DateTimeUtilities, type: :lib do
  let(:central_time) { ActiveSupport::TimeZone["Central Time (US & Canada)"] }
  let(:pacific_time) { ActiveSupport::TimeZone["Pacific Time (US & Canada)"] }

  context 'when converts date_time objects to strings' do
    it 'prints times as a tutor API-friendly string' do
      Timecop.freeze('Aug 14, 2015 9:07 PM CST') do
        formatted_time = described_class.to_api_s(DateTime.current)
        expect(formatted_time).to eq('2015-08-15T03:07:00.000Z')
      end
    end
  end

  context 'when reading strings with time_zones' do
    it 'infers UTC if the string has no time_zone info' do
      date_time = described_class.from_s("2016-12-25 7:00")
      expect(date_time.zone).to eq "+00:00"
      expect(date_time.to_s).to eq "2016-12-25T07:00:00+00:00"
    end

    it 'reads time_zone from offset' do
      date_time = described_class.from_s("2016-12-25 7:00 -0500")
      expect(date_time.zone).to eq "-05:00"
      expect(date_time.to_s).to eq "2016-12-25T07:00:00-05:00"
    end

    it 'reads time_zone from name' do
      date_time = described_class.from_s("2016-12-25 7:00 PST")
      expect(date_time.zone).to eq "-08:00"
      expect(date_time.to_s).to eq "2016-12-25T07:00:00-08:00"
    end

    it 'reads time_zone of the form -05' do
      date_time = described_class.from_s("2016-12-25 7:00 -05")
      expect(date_time.zone).to eq "-05:00"
      expect(date_time.to_s).to eq "2016-12-25T07:00:00-05:00"
    end

    it 'reads time_zone of the form -05:00' do
      date_time = described_class.from_s("2016-12-25 7:00-05:00")
      expect(date_time.zone).to eq "-05:00"
      expect(date_time.to_s).to eq "2016-12-25T07:00:00-05:00"
    end

    it 'reads W3CZ format' do
      reference_time = Time.utc(2007,2,10,20,30,45).to_datetime
      w3c_time_string = described_class.to_api_s(reference_time)
      date_time = described_class.from_s(w3c_time_string)
      expect(date_time.zone).to eq "+00:00"
      expect(date_time.to_s).to eq "2007-02-10T20:30:45+00:00"
    end
  end

  context 'when removing time_zone information' do
    it 'drops time_zones including their offsets' do
      date_time = described_class.from_s("2016-12-25 7:00 -0500")
      date_time_without_tz = described_class.remove_tz(date_time)
      expect(date_time_without_tz.zone).to eq "UTC"
      expect(date_time_without_tz.to_s).to eq "2016-12-25 07:00:00 UTC"
    end
  end

  context 'when applying time_zone information' do
    it 'applies time_zones to UTC date_times' do
      date_time = Time.utc(2007,2,10,20,30,45).to_datetime

      time_with_zone = described_class.apply_tz(date_time, central_time)
      expect(time_with_zone.to_s).to eq "2007-02-10 20:30:45 -0600"

      time_with_zone = described_class.apply_tz(date_time, pacific_time)
      expect(time_with_zone.to_s).to eq "2007-02-10 20:30:45 -0800"
    end
  end

  context '#parse_in_zone' do
    it 'parses a date correctly' do
      date_time = described_class.parse_in_zone(string: "5/25/17", zone: "Eastern Time (US & Canada)")
      expect(date_time.to_s).to eq "2017-05-25T12:00:00-04:00"
    end
  end
end
