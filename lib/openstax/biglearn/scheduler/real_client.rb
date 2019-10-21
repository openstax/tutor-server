class OpenStax::Biglearn::Scheduler::RealClient < OpenStax::Biglearn::RealClient
  # student is a CourseMembership::Models::Student
  # task is a Tasks::Models::Task

  # Retrieves the scheduler calculation that will be used next
  # for the given student or that has been used for the given task
  # Requests is an array of hashes containing one or both of the following keys:
  # :student and :task
  def fetch_algorithm_exercise_calculations(requests)
    scheduler_requests = requests.flat_map do |request|
      student = request[:student]
      task = request[:task]

      calculation_uuids = [task&.pe_calculation_uuid, task&.spe_calculation_uuid].compact
      if calculation_uuids.empty?
        [ { student_uuid: student.present? ? student.uuid: task.taskings.first.role.student.uuid } ]
      else
        calculation_uuids.map do |calculation_uuid|
          { calculation_uuid: calculation_uuid }.tap do |scheduler_request|
            scheduler_request[:student_uuid] = student.uuid unless student.nil?
          end
        end
      end
    end

    bulk_api_request url: :fetch_algorithm_exercise_calculations, requests: scheduler_requests
  end

  protected

  def token_header
    'Biglearn-Scheduler-Token'
  end
end
