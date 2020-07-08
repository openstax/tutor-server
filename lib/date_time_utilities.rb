Time::DATE_FORMATS[:w3cz] = ->(time) { time.utc.strftime("%Y-%m-%dT%H:%M:%S.%LZ") }

module DateTimeUtilities
  # Convert the given DateTime to a W3CZ formatted string
  def self.to_api_s(date_time)
    date_time.try(:to_formatted_s, :w3cz)
  end

  # Parse a string representing a DateTime
  # If no time zone is given, UTC is assumed
  def self.from_s(string)
    DateTime.parse(string.to_s) rescue nil
  end

  # Apply a timezone to the given DateTime object (without offset)
  # Example: 2 PM UTC -> 2 PM EST
  def self.apply_tz(date_time, timezone)
    return if date_time.nil?

    RequestStore.store[:apply_tz_cache] ||= Hash.new { |hash, key| hash[key] = {} }
    RequestStore.store[:apply_tz_cache][date_time][timezone] ||= begin
      date_time = date_time.in_time_zone(timezone)
      date_time - date_time.utc_offset
    end
  end

  # Removes the timezone from DateTime object (removing its offset)
  # Example: 2 PM EST -> 2 PM UTC
  def self.remove_tz(date_time)
    date_time.try(:to_datetime).try(:change, offset: 0).try(:in_time_zone, 'UTC')
  end

 def self.parse_in_zone(string:, zone:)
    datetime = nil

    begin
      if zone.present?
        original_timezone = Time.zone
        original_chronic_time_class = Chronic.time_class

        Time.zone = zone
        Chronic.time_class = Time.zone
      end

      datetime = Chronic.parse(string)
    ensure
      if zone.present?
        Time.zone = original_timezone
        Chronic.time_class = original_chronic_time_class
      end
    end

    DateTime.parse(datetime.to_s)
  end
end
