require "timecop"
class Timecop
  def self.enabled?
    Rails.application.secrets[:timecop_enable]
  end

  def self.travel_all(time)
    self.return
    Settings.timecop_offset = time - Time.now
    travel(time)
  end

  def self.return_all
    self.return
    Settings.timecop_offset = nil
  end

  def self.load_time
    self.return
    offset = Settings.timecop_offset
    travel(Time.now + offset) unless offset.nil?
  end
end

Timecop.load_time if Timecop.enabled?
