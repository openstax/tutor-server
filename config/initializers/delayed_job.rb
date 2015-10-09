# Defaults:
# Delayed::Worker.destroy_failed_jobs = true
# Delayed::Worker.sleep_delay = 5
# Delayed::Worker.max_attempts = 25
# Delayed::Worker.max_run_time = 4.hours
# Delayed::Worker.read_ahead = 5
# Delayed::Worker.default_queue_name = nil
# Delayed::Worker.delay_jobs = true
# Delayed::Worker.raise_signal_exceptions = false
# Delayed::Worker.logger = Rails.logger

# Keep failed jobs for later inspection
Delayed::Worker.destroy_failed_jobs = false

# Should be longer than the longest background job (that actually uses this gem)
Delayed::Worker.max_run_time = 10.minutes

# Allows us to use this gem in tests instead of setting the ActiveJob adapter to :inline
Delayed::Worker.delay_jobs = Rails.env.production? || (
                               Rails.env.development? && \
                               EnvUtilities.load_boolean(name: 'USE_REAL_BACKGROUND_JOBS',
                                                         default: false)
                             )
