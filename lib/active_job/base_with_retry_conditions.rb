require 'active_job/provider_job_id_backport'

module ActiveJob
  class BaseWithRetryConditions < Base
    NEVER_RETRY = ->(exception) { false }

    JOB_RETRY_CONDITIONS = {
      'ActiveJob::DeserializationError' => NEVER_RETRY,
      'ActiveRecord::RecordInvalid' => NEVER_RETRY,
      'ActiveRecord::RecordNotFound' => NEVER_RETRY,
      'Addressable::URI::InvalidURIError' => NEVER_RETRY,
      'ArgumentError' => NEVER_RETRY,
      'Content::MapInvalidError' => NEVER_RETRY,
      'JSON::ParserError' => NEVER_RETRY,
      'NoMethodError' => NEVER_RETRY,
      'NotYetImplemented' => NEVER_RETRY,
      'OAuth2::Error'       => ->(exception) {
        status = exception.response.status
        status < 400 || status >= 500
      },
      'OpenStax::HTTPError' => ->(exception) {
        status = exception.message.to_i
        status < 400 || status >= 500
      },
      'OpenURI::HTTPError'  => ->(exception) {
        status = exception.message.to_i
        status < 400 || status >= 500
      }
    }

    around_perform do |job, block|
      begin
        block.call
      rescue StandardError => exception
        retry_proc = JOB_RETRY_CONDITIONS[exception.class.name]

        # Fail the job immediately if it is not retryable
        if retry_proc.present? && !retry_proc.call(exception)
          case job.class.queue_adapter.name
          when 'ActiveJob::QueueAdapters::DelayedJobAdapter'
            # Attempt to fail the job, but don't blow up if no job was found,
            # which can happen, for example, if ::Delayed::Worker.delay_jobs = false (dev, test)
            ::Delayed::Job.find_by(id: job.provider_job_id).try(:fail!)
          else
            # Since we don't know how to mark the job as failed, mark it as succeeded instead
            return
          end
        end

        # Prevent the job from succeeding
        raise exception
      end
    end
  end
end
