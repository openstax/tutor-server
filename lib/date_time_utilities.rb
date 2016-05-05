Time::DATE_FORMATS[:w3cz] = lambda { |time| time.utc.strftime("%Y-%m-%dT%H:%M:%S.%LZ") }

module DateTimeUtilities
  def self.to_api_s(time)
    time.try(:to_formatted_s, :w3cz)
  end

  def self.from_string(datetime_string:, time_zone: nil, ignore_existing_zone: true)
    time_zone ||= Time.zone

    raise(IllegalArgument, "time_zone must not be nil") if time_zone.nil?

    if ignore_existing_zone
      datetime_string.gsub!(/(\d)T(\d)/,'\1 \2') # handle the 'T' in w3c format
      datetime_string.gsub!(/[-+]\d\d\d\d/,'')  # remove time zone offsets
      datetime_string.gsub!(/[a-zA-Z]/,'')      # remove any other PST or similar
      datetime_string.strip!
    else
      raise NotYetImplemented
    end

    original_time_class = Chronic.time_class
    begin
      Chronic.time_class = time_zone
      Chronic.parse(datetime_string)
    ensure
      Chronic.time_class = original_time_class
    end
  end
end
