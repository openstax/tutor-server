class LevJobReturningJob < Lev::ActiveJob::Base
  def perform_later(routine_class, options, *args, &block)
    # Create a new status object
    status = routine_class.create_status

    # Push the routine class name on to the arguments
    # so that we can run the correct routine in `perform`
    args.push(routine_class.to_s)

    # Push the status's ID on to the arguments so that in `perform`
    # it can be used to retrieve the status when the routine is initialized
    args.push(status.id)

    # Set the job_name
    status.set_job_name(routine_class.name)

    # In theory we'd mark as queued right after the call to super, but this messes
    # up when the activejob adapter runs the job right away (inline mode)
    status.queued!

    # Queue up the job and set the provider_job_id
    # For delayed_job, requires either Rails 5 or
    # http://stackoverflow.com/questions/29855768/rails-4-2-get-delayed-job-id-from-active-job
    job = self.class.send(:job_or_instantiate, *args, &block).enqueue(options)

    status.set_provider_job_id(job.provider_job_id) \
      if job.provider_job_id.present? && status.respond_to?(:set_provider_job_id)

    # Return the job
    job
  end
end
