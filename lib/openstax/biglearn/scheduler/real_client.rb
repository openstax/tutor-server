class OpenStax::Biglearn::Scheduler::RealClient < OpenStax::Biglearn::RealClient
  # algorithm_name is a String
  # student is a CourseMembership::Models::Student
  # task is a Tasks::Models::Task

  # Retrieves the scheduler calculation that will be used next
  # for the given student or that has been used for the given task
  # Requests is an array of hashes containing :algorithm_name and one or both of the following keys:
  # :student and :task
  def fetch_algorithm_exercise_calculations(requests)
    scheduler_requests = requests.map do |request|
      student = request[:student]
      task = request[:task]

      calculation_uuids = [ task&.pe_calculation_uuid, task&.spe_calculation_uuid ].compact
      if calculation_uuids.empty? && student.nil?
        student = task&.taskings&.first&.role&.student
        next if student.nil?
      end

      request.slice(:request_uuid, :algorithm_name).tap do |scheduler_request|
        scheduler_request[:student_uuid] = student.uuid unless student.nil?
        scheduler_request[:calculation_uuids] = calculation_uuids unless calculation_uuids.empty?
      end
    end.compact

    bulk_api_request url: :fetch_algorithm_exercise_calculations,
                     requests: scheduler_requests,
                     requests_key: :algorithm_exercise_calculation_requests,
                     responses_key: :algorithm_exercise_calculations
  end

  protected

  def token_header
    'Biglearn-Scheduler-Token'
  end
end