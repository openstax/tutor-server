class Api::V1::Research::SparfaController < Api::V1::Research::BaseController
  api :POST, '/research/sparfa/students', 'Retrieve SPARFA information about the given students'
  description <<-EOS
    Retrieve SPARFA information about students with the given research_identifiers.
  EOS
  def students
    request = Hashie::Mash.new
    consume! request, represent_with: Api::V1::Research::SparfaRequestRepresenter
    research_identifiers = request.research_identifiers
    render_api_errors('research_identifiers must be provided') if research_identifiers.nil?

    students = CourseMembership::Models::Student.joins(:role).where(
      role: { research_identifier: research_identifiers }
    )

    respond_with students,
                 represent_with: Api::V1::Research::Sparfa::StudentWithEcosystemMatrixRepresenter
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
    render_api_errors('Either task_ids or research_identifiers must be provided') \
      if task_plan_ids.nil? && research_identifiers.nil?

    task_plans = Tasks::Models::TaskPlan.all
    task_plans = task_plans.where(id: task_plan_ids) unless task_plan_ids.nil?
    task_plans = task_plans.joins(tasks: { taskings: :role }).where(
      tasks: { taskings: { role: { research_identifier: research_identifiers } } }
    ) unless research_identifiers.nil?

    respond_with task_plans, represent_with: Api::V1::Research::Sparfa::TaskPlanRepresenter,
                             user_options: { research_identifiers: research_identifiers }
  end
end
