Lev.configure do |config|
  config.raise_fatal_errors = false
  config.active_job_class = TrackableJob
end
