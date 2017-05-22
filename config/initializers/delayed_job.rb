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

# Should be longer than the longest background job
Delayed::Worker.max_run_time = Rails.application.secrets['background_worker_timeout']

# Allows us to use this gem in tests instead of setting the ActiveJob adapter to :inline
Delayed::Worker.delay_jobs = Rails.env.production? || (
                               Rails.env.development? &&
                               EnvUtilities.load_boolean(
                                 name: 'USE_REAL_BACKGROUND_JOBS', default: false
                               )
                             )

# https://github.com/smartinez87/exception_notification/issues/195#issuecomment-31257207
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
      exception.original_exception.is_a? ActiveRecord::RecordNotFound
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

  def handle_failed_job_with_instant_failures(job, exception)
    fail_proc = INSTANT_FAILURE_PROCS[exception.class.name]
    job.fail! if fail_proc.present? && fail_proc.call(exception)

    handle_failed_job_without_instant_failures(job, exception)
  end

  alias_method_chain :handle_failed_job, :instant_failures
end

# Fix NewRelic's broken DJ monkeypatch
# Without this fix, a second call to Delayed::Worker.new
# will cause the worker to enter an infinite loop
Delayed::Worker.class_exec do
  def initialize_with_new_relic_fix(*args)
    Delayed::Job.method_defined?(:invoke_job_without_new_relic) ?
      initialize_without_new_relic(*args) : initialize_without_new_relic_fix(*args)
  end

  alias initialize_without_new_relic_fix initialize
  alias initialize initialize_with_new_relic_fix
end

# http://stackoverflow.com/questions/29855768/rails-4-2-get-delayed-job-id-from-active-job
ActiveJob::Base.class_exec do
  attr_accessor :provider_job_id

  def self.execute(job_data, provider_job_id = nil)
    job = deserialize(job_data)
    job.provider_job_id = provider_job_id
    job.perform_now
  end
end

ActiveJob::QueueAdapters::DelayedJobAdapter.class_exec do
  class << self
    def enqueue(job) #:nodoc:
      delayed_job = Delayed::Job.enqueue(
        ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.serialize),
        queue: job.queue_name
      )
      job.provider_job_id = delayed_job.id
      delayed_job
    end

    def enqueue_at(job, timestamp) #:nodoc:
      delayed_job = Delayed::Job.enqueue(
        ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.serialize),
        queue: job.queue_name,
        run_at: Time.at(timestamp)
      )
      job.provider_job_id = delayed_job.id
      delayed_job
    end
  end
end

ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.class_exec do
  attr_reader :job_data
  attr_reader :provider_job_id

  def initialize(job_data)
    @job_data = job_data
  end

  def before(delayed_job)
    @provider_job_id = delayed_job.id
  end

  def perform
    ActiveJob::Base.execute(job_data, provider_job_id)
  end
end
