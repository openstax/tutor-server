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

# Poll the database every second to reduce delay (number of workers = number of queries per second)
Delayed::Worker.sleep_delay = 1

# Default queue name if not specified in the job class
Delayed::Worker.default_queue_name = :default

# max_run_time must be longer than the longest-running job
Delayed::Worker.max_run_time = 8.hours

# Default queue priorities
Delayed::Worker.queue_attributes = {
  default:     { priority:  0 },
  dashboard:   { priority:  5 },
  maintenance: { priority: 10 },
  preview:     { priority: 15 }
}

# Allows us to use this gem in tests instead of setting the ActiveJob adapter to :inline
Delayed::Worker.delay_jobs = Rails.env.production? || (
                               Rails.env.development? &&
                               EnvUtilities.load_boolean(
                                 name: 'USE_REAL_BACKGROUND_JOBS', default: false
                               )
                             )

module HandleFailedJobInstantly
  # Based on https://github.com/smartinez87/exception_notification/issues/195#issuecomment-31257207
  def handle_failed_job(job, exception)
    fail_proc = INSTANT_FAILURE_PROCS[exception.class.name]
    job.fail! if fail_proc.present? && fail_proc.call(exception) ||
                 exception.try(:instantly_fail_if_in_background_job?)

    super(job, exception)
  end
end

Delayed::Worker.class_exec do
  ALWAYS_FAIL = ->(exception) { true }

  INSTANT_FAILURE_PROCS = {
    'ActiveRecord::RecordInvalid' => ALWAYS_FAIL,
    'ActiveRecord::RecordNotFound' => ALWAYS_FAIL,
    'Addressable::URI::InvalidURIError' => ALWAYS_FAIL,
    'ArgumentError' => ALWAYS_FAIL,
    'Content::MapInvalidError' => ALWAYS_FAIL,
    'JSON::ParserError' => ALWAYS_FAIL,
    'NoMethodError' => ALWAYS_FAIL,
    'NotYetImplemented' => ALWAYS_FAIL,
    # http://stackoverflow.com/a/31928089
    'ActiveJob::DeserializationError' => ->(exception) do
      exception.message.include? ActiveRecord::RecordNotFound.to_s
    end,
    'OAuth2::Error'       => ->(exception) do
      status = exception.response.status
      400 <= status && status < 500
    end,
    'OpenStax::HTTPError' => ->(exception) do
      status = exception.message.to_i
      400 <= status && status < 500
    end,
    'OpenURI::HTTPError'  => ->(exception) do
      status = exception.message.to_i
      400 <= status && status < 500
    end
  }

  def self.delay_jobs
    RequestStore.store[:delay_jobs] ||= class_variable_get(:@@delay_jobs)
  end

  # Note: Make sure this method is redefined only after the global delay_jobs is set above
  def self.delay_jobs=(value)
    RequestStore.store[:delay_jobs] = value
  end

  def self.with_delay_jobs(value, &block)
    begin
      original_value = delay_jobs
      self.delay_jobs = value
      block.call
    ensure
      self.delay_jobs = original_value
    end
  end

  prepend HandleFailedJobInstantly
end
