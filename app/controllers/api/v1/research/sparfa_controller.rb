class Api::V1::Research::SparfaController < Api::V1::Research::BaseController
  ALGORITHM_NAME = 'biglearn_sparfa'

  api :POST, '/research/sparfa/students', 'Retrieve SPARFA information about the given students'
  description <<-EOS
    Retrieve SPARFA information about students with the given research_identifiers.
  EOS
  def students
    request = Hashie::Mash.new
    consume! request, represent_with: Api::V1::Research::SparfaRequestRepresenter
    research_identifiers = request.research_identifiers
    render_api_errors('research_identifiers must be provided') if research_identifiers.nil?

    ordered_exercise_numbers_by_student_uuid = {}
    ecosystem_matrix_by_student_uuid = {}
    CourseMembership::Models::Student.joins(:role).where(
      role: { research_identifier: research_identifiers }
    ).find_in_batches(batch_size: 10) do |students|
      scheduler_requests = students.map do |student|
        { algorithm_name: ALGORITHM_NAME, student: student }
      end
      calcs = OpenStax::Biglearn::Scheduler.fetch_algorithm_exercise_calculations(
        scheduler_requests
      ).values.flatten
      calcs.each do |calc|
        ordered_exercise_numbers_by_student_uuid[calc[:student_uuid]] = \
          calc[:exercises].map(&:number)
      end

      sparfa_requests = calcs.map do |calc|
        calc.slice(:ecosystem_matrix_uuid).merge(
          student_uuids: [ calc[:student_uuid] ],
          responded_before: calc[:calculated_at]
        )
      end
      OpenStax::Biglearn::Sparfa.fetch_ecosystem_matrices(
        sparfa_requests
      ).each do |ecosystem_matrix|
        ecosystem_matrix_by_student_uuid[ecosystem_matrix[:L_ids].first] = ecosystem_matrix
      end
    end

    responses = students.map do |student|
      Hashie::Map.new student.attributes.merge (
        ordered_exercise_numbers: ordered_exercise_numbers_by_student_uuid[student.uuid],
        ecosystem_matrix: ecosystem_matrix_by_student_uuid[student.uuid]
      )
    end

    respond_with responses,
                 represent_with: Api::V1::Research::Sparfa::StudentRepresenter
  end

  api :POST, '/research/sparfa/task_plans', 'Retrieve SPARFA information about the given task_plans'
  description <<-EOS
    Retrieve SPARFA information about task_plans with the given
    task_plan_ids or for students with the given research_identifiers.
  EOS
  def task_plans
    request = Hashie::Mash.new
    consume! request, represent_with: Api::V1::Research::SparfaRequestRepresenter
    task_plan_ids = request.task_plan_ids
    research_identifiers = request.research_identifiers
    render_api_errors('Either task_plan_ids or research_identifiers must be provided') \
      if task_plan_ids.nil? && research_identifiers.nil?

    tasks = Tasks::Models::Task.joins(:task_plan).preload(:task_plan)
    tasks = tasks.where(task_plan: { id: task_plan_ids }) unless task_plan_ids.nil?
    tasks = tasks.joins(taskings: :role).where(
      taskings: { role: { research_identifier: research_identifiers } }
    ) unless research_identifiers.nil?

    ordered_ex_nums_by_calc_uuid = {}
    calculation_uuids_by_ecosystem_matrix_uuid = Hash.new { |hash, key| hash[key] = [] }
    ecosystem_matrix_by_calculation_uuid = {}
    tasks.find_in_batches(batch_size: 10) do |tasks|
      scheduler_requests = tasks.map { |task| { algorithm_name: ALGORITHM_NAME, task: task } }
      calcs = OpenStax::Biglearn::Scheduler.fetch_algorithm_exercise_calculations(
        scheduler_requests
      ).values.flatten
      calcs.each do |calc|
        calculation_uuid = calc[:calculation_uuid]
        ordered_ex_nums_by_calc_uuid[calculation_uuid] = calc[:exercises].map(&:number)
        calculation_uuids_by_ecosystem_matrix_uuid[calc[:ecosystem_matrix_uuid]] << calculation_uuid
      end

      sparfa_requests = calcs.map do |calc|
        calc.slice(:ecosystem_matrix_uuid).merge(
          student_uuids: [ calc[:student_uuid] ],
          responded_before: calc[:calculated_at]
        )
      end
      OpenStax::Biglearn::Sparfa.fetch_ecosystem_matrices(
        sparfa_requests
      ).each do |ecosystem_matrix|
        calculation_uuids = \
          calculation_uuids_by_ecosystem_matrix_uuid[ecosystem_matrix[:ecosystem_matrix_uuid]]
        calculation_uuids.each do |calculation_uuid|
          ecosystem_matrix_by_calculation_uuid[calculation_uuid] = ecosystem_matrix
        end
      end
    end

    responses = tasks.group_by(&:task_plan).map do |task_plan, tasks|
      Hashie::Map.new task_plan.attributes.merge(
        students: tasks.map do |task|
          student = task.taskings.first.role.student

          student.attributes.tap do |attrs|
            attrs[:pes] = {
              ordered_exercise_numbers: ordered_ex_nums_by_calc_uuid[task.pe_calculation_uuid],
              ecosystem_matrix: ecosystem_matrix_by_calculation_uuid[task.pe_calculation_uuid]
            } unless task.pe_calculation_uuid.nil?
            spes: {
              ordered_exercise_numbers: ordered_ex_nums_by_calc_uuid[task.spe_calculation_uuid],
              ecosystem_matrix: ecosystem_matrix_by_calculation_uuid[task.spe_calculation_uuid]
            }
          }
        end
      )
    end

    respond_with responses, represent_with: Api::V1::Research::Sparfa::TaskPlanRepresenter,
                             user_options: { research_identifiers: research_identifiers }
  end
end
