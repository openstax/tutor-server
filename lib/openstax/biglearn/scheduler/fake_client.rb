class OpenStax::Biglearn::Scheduler::FakeClient < OpenStax::Biglearn::FakeClient
  # student is a CourseMembership::Models::Student
  # task is a Tasks::Models::Task

  # Retrieves the scheduler calculation that will be used next
  # for the given student or that has been used for the given task
  # Requests is an array of hashes containing one or both of the following keys:
  # :student and :task
  def fetch_algorithm_exercise_calculations(requests)
    requests.map do |request|
      algorithm_name = request[:algorithm_name] || ['local_query', 'biglearn_sparfa'].sample
      task = request[:task]
      next if !task.nil? && task.taskings.empty?

      student = request[:student] || task.taskings.first.role.student
      next if !task.nil? && task.taskings.none? { |tasking| tasking.role.student == student }

      calculation_uuids = [ task&.pe_calculation_uuid, task&.spe_calculation_uuid ].compact
      calculation_uuids = [ SecureRandom.uuid ] if calculation_uuids.empty?

      ecosystem = task.nil? ? student.course.ecosystems.first : task.ecosystem

      request.slice(:request_uuid).merge(
        calculations: calculation_uuids.map do |calculation_uuid|
          {
            student_uuid: student.uuid,
            calculation_uuid: calculation_uuid,
            calculated_at: Time.current.iso8601,
            ecosystem_matrix_uuid: SecureRandom.uuid,
            algorithm_name: algorithm_name,
            exercise_uuids: ecosystem.exercises.map(&:uuid).shuffle
          }
        end
      )
    end.compact
  end
end
