Time::DATE_FORMATS[:w3cz] = lambda { |time| time.utc.strftime("%Y-%m-%dT%H:%M:%S.%LZ") }

module DateTimeUtilities
  def self.to_api_s(time)
    time.to_formatted_s(:w3cz)
  end

  def self.from_api_s(time)
    Chronic.parse(time)
  end
end
