class GetDashboard
  include DashboardRoutineMethods

  uses_routine Tasks::GetTaskPlans, as: :get_plans
  uses_routine ShortCode::UrlFor, as: :get_short_code_url

  protected

  def exec(course:, role:, start_at_ntz: nil, end_at_ntz: nil)
    if course.is_concept_coach
      fatal_error(code: :cc_course)
      return
    end

    load_role(role)
    load_course(course)
    load_research_surveys(course, role) if role.student?
    load_tasks(role, start_at_ntz, end_at_ntz)
    load_plans(course, start_at_ntz, end_at_ntz) if role.teacher?
  end

  def load_research_surveys(course, role)
    surveys = role.student.surveys
                          .preload(:survey_plan)
                          .where(completed_at: nil, hidden_at: nil, deleted_at: nil)
    outputs.research_surveys = surveys if surveys.any?
  end

  def load_plans(course, start_at_ntz, end_at_ntz, current_time = Time.current)
    result = run(
      :get_plans, course: course, start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz
    ).outputs

    outputs.plans = result.plans.map do |task_plan|
      task_plan.attributes.symbolize_keys.except(:is_draft, :is_publishing, :is_published).merge(
        is_draft?: task_plan.is_draft?,
        is_publishing?: task_plan.is_publishing?,
        is_published?: task_plan.is_published?,
        shareable_url: run(:get_short_code_url, task_plan, suffix: task_plan.title).outputs.url,
        gradable_step_count: task_plan.gradable_step_count,
        ungraded_step_count: task_plan.ungraded_step_count,
        tasking_plans: task_plan.tasking_plans
      )
    end
  end
end
