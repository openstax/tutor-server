class OpenStax::Biglearn::Scheduler::FakeClient < OpenStax::Biglearn::FakeClient
  # student is a CourseMembership::Models::Student
  # task is a Tasks::Models::Task

  # Retrieves the scheduler calculation that will be used next
  # for the given student or that has been used for the given task
  # Requests is an array of hashes containing one or both of the following keys:
  # :student and :task
  def fetch_algorithm_exercise_calculations(requests)
    requests.map do |request|
      student = request[:student]
      task = request[:task]

      next if !student.nil? && !task.nil? && task.taskings.none? do |tasking|
        tasking.role.student == student
      end

      {
        request_uuid: request[:request_uuid],
        calculation_uuid: SecureRandom.uuid,
        ecosystem_matrix_uuid: SecureRandom.uuid,
        algorithm_name: ['local_query', 'biglearn_sparfa'].sample,
        exercise_uuids: rand(10000).times.map { SecureRandom.uuid }
      }
    end.compact
  end
end
