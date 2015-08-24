Time::DATE_FORMATS[:w3cz] = lambda { |time| time.utc.strftime("%Y-%m-%dT%H:%M:%S.%LZ") }

module DateTimeUtilities
  def self.to_api_s(time)
    time.try(:to_formatted_s, :w3cz)
  end

  def self.opens_at_from_api_s(time_str)
    time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
    orig_time = time_zone.parse(extract_date_portion(time_str))
    new_time  = orig_time.nil? ? nil : orig_time.in_time_zone(time_zone).midnight + 1.minute
    new_time
  end

  def self.due_at_from_api_s(time_str)
    time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
    orig_time = time_zone.parse(extract_date_portion(time_str))
    new_time  = orig_time.nil? ? nil : orig_time.in_time_zone(time_zone).midnight + 7.hours
    new_time
  end

  def self.extract_date_portion(string)
    results1 = /\b(\d\d\d\d)-(\d\d)-(\d\d)\b/.match(string)
    results2 = /\b(\d\d\d\d)(\d\d)(\d\d)\b/.match(string)

    captures = results1.to_a + results2.to_a

    raise "string contains no date portions (#{string})" \
      if captures.count == 0

    raise "string contains multiple date portions (#{string})" \
      if captures.count > 4

    year, month, day = captures[1..3]

    date_portion = "#{year}-#{month}-#{day}"
    date_portion
  end
end
