class OpenStax::Biglearn::Api::JobWithSequenceNumber < OpenStax::Biglearn::Api::Job
  BIGLEARN_API_TIMEOUT = 10.minutes

  queue_as :default

  def perform(method:, requests:, create:,
              sequence_number_model_key:, sequence_number_model_class:)
    req = [requests].flatten
    sequence_number_model_key = sequence_number_model_key.to_sym

    model_ids = req.map { |request| request[sequence_number_model_key].id }.compact
    model_id_counts = {}
    model_ids.each { |model_id| model_id_counts[model_id] = (model_id_counts[model_id] || 0) + 1 }

    sequence_number_model_class = sequence_number_model_class.constantize \
      if sequence_number_model_class.respond_to?(:constantize)
    table_name = sequence_number_model_class.table_name

    cases = model_id_counts.map do |model_id, count|
      "WHEN #{model_id} THEN #{count}"
    end
    increments = "CASE \"id\" #{cases.join(' ')} END"
    sequence_number_sql = <<-SQL.strip_heredoc
      UPDATE #{table_name}
      SET "sequence_number" = "sequence_number" + #{increments}
      WHERE "#{table_name}"."id" IN (#{model_ids.join(', ')})
      #{'  AND "sequence_number" > 0' unless create}
      RETURNING "id", "sequence_number"
    SQL

    can_perform_later = Delayed::Worker.delay_jobs

    job_or_result = sequence_number_model_class.transaction do
      # Update and read all sequence_numbers in one statement to minimize time waiting for I/O
      # Requests for records that have not been created
      # on the Biglearn side (sequence_number == 0) are suppressed
      sequence_numbers_by_model_id = {}
      sequence_number_model_class.connection.execute(sequence_number_sql).each do |hash|
        id = hash['id'].to_i
        sequence_numbers_by_model_id[id] = hash['sequence_number'].to_i - model_id_counts[id]
      end unless model_ids.empty?

      # From this point on, if the current transaction commits, those requests MUST be sent to
      # biglearn-api or else they will cause gaps in the sequence_number
      # If aborting a request after this point without rolling back the transaction is required
      # in the future, we will need to introduce NO-OP Events in biglearn-api
      requests_with_sequence_numbers = req.map do |request|
        model = request[sequence_number_model_key].to_model

        if model.new_record?
          # Special case for unsaved records
          sequence_number = model.sequence_number || 0
          next if sequence_number == 0 && !create

          can_peform_later = false

          model.sequence_number = sequence_number + 1
          next request.merge(sequence_number: sequence_number)
        end

        sequence_number = sequence_numbers_by_model_id[model.id]
        # Requests for records that have not been created
        # on the Biglearn side (sequence_number == 0) are suppressed
        next if sequence_number.nil?

        next_sequence_number = sequence_number + 1
        sequence_numbers_by_model_id[model.id] = next_sequence_number

        # Make sure the provided model has the new sequence_number
        # and mark the attribute as persisted
        model.sequence_number = next_sequence_number
        model.previous_changes[:sequence_number] = model.changes[:sequence_number]
        model.send :clear_attribute_changes, :sequence_number

        # Call the given block with the previous sequence_number
        request.merge(sequence_number: sequence_number)
      end.compact

      # If an array was given, call the block with an array
      # If another type of argument was given, extract the block argument from the array
      modified_requests = requests.is_a?(Hash) ? requests_with_sequence_numbers.first :
                                                 requests_with_sequence_numbers

      # nil can happen if the request was suppressed
      return {} if modified_requests.nil?
      return [] if modified_requests.empty?

      # Create a background job if possible to guarantee the sequence_number will reach Biglearn
      if can_perform_later
        # Destroy the current job so it's removed from the queue when this transaction commits
        # Just in case we encounter an error after the transaction ends,
        # since we don't want this job to run again
        Delayed::Job.where(id: provider_job_id).delete_all

        OpenStax::Biglearn::Api::Job.perform_later(
          method: method.to_s, requests: modified_requests
        )
      else
        super(method: method, requests: modified_requests)
      end
    end

    return job_or_result unless can_perform_later

    delayed_job_id = job_or_result.provider_job_id

    return job_or_result if delayed_job_id.nil?

    # Attempt to lock and run the Biglearn request job inline to speed up Biglearn responses
    worker = Delayed::Worker.new
    ready_scope = Delayed::Job.ready_to_run(worker.name, Delayed::Worker.max_run_time)
                              .where(id: delayed_job_id)
    # Pretend the lock is much closer to expiring so we get a shorter timeout
    now = Delayed::Job.db_time_now - Delayed::Worker.max_run_time + BIGLEARN_API_TIMEOUT
    delayed_job = Delayed::Job.reserve_with_scope(ready_scope, worker, now)

    return job_or_result if delayed_job.nil?

    worker.run(delayed_job)
  end
end
