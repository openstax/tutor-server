# Generates a unique gapless sequence number for each request given,
# then queues up another job to make the Biglearn request itself
# Then attempts to lock the job and, after the transaction is committed, work it inline
class OpenStax::Biglearn::Api::JobWithSequenceNumber < OpenStax::Biglearn::Api::Job
  queue_as :biglearn

  def self.perform_later(*_)
    super.tap do |job|
      # Attempt to get the sequence_number as soon as the current transaction (if any) ends
      # This should guarantee that the intended order of events is preserved unless the server dies
      # in-between committing the transaction and running the after_commit callbacks
      # (in that case we'll still get the events eventually but they may be in the wrong order)
      ActiveJob::AfterCommitRunner.new(job).run_after_commit
    end
  end

  def perform(
    method:, requests:, create:, sequence_number_model_key:, sequence_number_model_class:, queue:,
    response_status_key: nil, accepted_response_status: []
  )
    ScoutHelper.ignore!(0.8)
    req = [requests].flatten
    return [] if req.empty?

    sequence_number_model_key = sequence_number_model_key.to_sym

    model_ids = req.map { |request| request[sequence_number_model_key].id }.compact
    model_id_counts = {}
    model_ids.each { |model_id| model_id_counts[model_id] = (model_id_counts[model_id] || 0) + 1 }

    sequence_number_model_class = sequence_number_model_class.constantize \
      if sequence_number_model_class.respond_to?(:constantize)
    table_name = sequence_number_model_class.table_name

    cases = model_id_counts.map { |model_id, count| "WHEN #{model_id} THEN #{count}" }
    increments = "CASE \"id\" #{cases.join(' ')} END"
    sequence_number_sql = <<-SQL.strip_heredoc
      UPDATE #{table_name}
      SET "sequence_number" = "sequence_number" + #{increments}
      WHERE "#{table_name}"."id" IN (#{model_ids.join(', ')})
      RETURNING "id", "sequence_number"
    SQL

    sequence_number_model_class.transaction do
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
        model = request[sequence_number_model_key]

        # Unsaved sequence_number_models are not supported (ActiveJob cannot serialize them)
        raise(
          ArgumentError,
          "The given #{sequence_number_model_class.name} is unsaved."
        ) if model.new_record?

        sequence_number = sequence_numbers_by_model_id[model.id]

        # Detect a race condition with the create call and potentially retry later
        raise(
          OpenStax::Biglearn::Api::JobFailed,
          "[#{method}] Attempted to get sequence_number 0 (reserved for \"create\" calls) from #{
          sequence_number_model_class} ID #{model.id}"
        ) if sequence_number == 0 && !create

        # The condition below should never happen unless we have a bug
        raise(
          ArgumentError,
          "[#{method}] The given #{sequence_number_model_class
          } with ID #{model.id} has already been created"
        ) if sequence_number > 0 && create

        next_sequence_number = sequence_number + 1
        sequence_numbers_by_model_id[model.id] = next_sequence_number

        # Make sure the provided model has the new sequence_number
        # and mark the attribute as persisted
        model.sequence_number = next_sequence_number
        model.previous_changes[:sequence_number] = model.changes[:sequence_number]
        model.send :clear_attribute_changes, [ :sequence_number ]

        # Call the given block with the previous sequence_number
        request.merge(sequence_number: sequence_number)
      end

      # If a hash was given, call the Biglearn client with a hash
      # If an array was given, call the Biglearn client with the array of requests
      modified_requests = requests.is_a?(Hash) ? requests_with_sequence_numbers.first :
                                                 requests_with_sequence_numbers

      # nil can happen if the request was suppressed
      return {} if modified_requests.nil?
      return [] if modified_requests.empty?

      # Create a background job to guarantee the sequence_number request will reach Biglearn
      OpenStax::Biglearn::Api::Job.set(queue: queue.to_sym).perform_later(
        method: method.to_s,
        requests: modified_requests,
        response_status_key: response_status_key.try!(:to_s),
        accepted_response_status: accepted_response_status
      )
    end
  end
end
