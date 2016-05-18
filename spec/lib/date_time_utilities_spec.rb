require 'rails_helper'

RSpec.describe DateTimeUtilities, type: :lib do
  it 'converts times to a tutor API friendly string' do
    Timecop.freeze('Aug 14, 2015 9:07 PM CST') do
      formatted_time = described_class.to_api_s(Time.current)
      expect(formatted_time).to eq('2015-08-15T03:07:00.000Z')
    end
  end

  context 'when reading time strings in zones' do
    it 'reads central time without string time zone info' do
      datetime = described_class.from_string(datetime_string: "12/25/16 7:00",
                                             time_zone: central_time)
      expect(datetime.zone).to eq "CST"
      expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0600"
    end

    it 'reads pacific time and ignores string time zone offset info' do
      datetime = described_class.from_string(datetime_string: "12/25/16 7:00 -0500",
                                             time_zone: pacific_time)
      expect(datetime.zone).to eq "PST"
      expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0800"
    end

    it 'reads pacific time and ignores string time zone name info' do
      datetime = described_class.from_string(datetime_string: "12/25/16 7:00 EST",
                                             time_zone: pacific_time)
      expect(datetime.zone).to eq "PST"
      expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0800"
    end

    it 'ignores time zone info of the form -07' do
      datetime = described_class.from_string(datetime_string: "12/25/16 7:00 -05",
                                             time_zone: pacific_time)
      expect(datetime.zone).to eq "PST"
      expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0800"
    end

    it 'ignores time zone info of the form -07:00' do
      datetime = described_class.from_string(datetime_string: "12/25/16 7:00 -05:00",
                                             time_zone: pacific_time)
      expect(datetime.zone).to eq "PST"
      expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0800"
    end

    it 'reads w3c time zone format with arbitrary zones applied' do
      reference_time = Time.utc(2007,2,10,20,30,45)
      w3c_time_string = described_class.to_api_s(reference_time)

      datetime = described_class.from_string(datetime_string: w3c_time_string,
                                             time_zone: central_time)
      expect(datetime.to_s).to eq "2007-02-10 20:30:45 -0600"

      datetime = described_class.from_string(datetime_string: w3c_time_string,
                                             time_zone: pacific_time)
      expect(datetime.to_s).to eq "2007-02-10 20:30:45 -0800"
    end

    it 'raises when asked to not ignore existing zone' do
      expect{
        described_class.from_string(datetime_string: "12/25/16 7:00",
                                    time_zone: central_time,
                                    ignore_existing_zone: false)
      }.to raise_error(NotYetImplemented)
    end

    it 'does not change Chronic.time_class permanently' do
      begin
        original_chronic_time_class = Chronic.time_class
        wellington = ActiveSupport::TimeZone["Wellington"]
        Chronic.time_class = wellington
        datetime = described_class.from_string(datetime_string: "12/25/16 7:00",
                                               time_zone: central_time)
        expect(datetime.to_s).to eq "2016-12-25 07:00:00 -0600"
        expect(Chronic.time_class).to eq wellington
      ensure
        Chronic.time_class = original_chronic_time_class
      end
    end
  end

  def central_time
    ActiveSupport::TimeZone["Central Time (US & Canada)"]
  end

  def pacific_time
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  end
end
