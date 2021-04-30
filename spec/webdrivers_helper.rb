require 'webdrivers'
require 'time'

# Download and cache the webdriver now so it doesn't interfere with VCR later
# Use a lockfile so we don't get errors due to downloading it multiple times concurrently
File.open('.webdrivers_update', File::RDWR|File::CREAT, 0640) do |file|
  file.flock File::LOCK_EX
  update_time = Time.parse(file.read) rescue nil
  current_time = Time.now

  if update_time.nil? || current_time - update_time > 300
    Webdrivers::Chromedriver.update

    file.rewind
    file.write current_time.iso8601
    file.flush
    file.truncate file.pos
  end
ensure
  file.flock File::LOCK_UN
end
