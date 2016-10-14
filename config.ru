# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

# Ensure that the main server process has the actual time
Timecop.return

run Rails.application
