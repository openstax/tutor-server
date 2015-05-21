class Timecop
  def self.enabled?
    Rails.application.secrets[:timecop_enable]
  end

  def self.store_time(time = Time.now)
    Settings.timecop_time = time
    freeze(time)
  end

  def self.clear_time
    Settings.timecop_time = nil
    self.return
  end

  def self.load_time
    time = Settings.timecop_time
    time.nil? ? self.return : freeze(time)
  end
end

Timecop.load_time if Timecop.enabled?
