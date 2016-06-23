class GetNonCcDashboard
  include DashboardRoutineMethods

  uses_routine Tasks::GetTaskPlans, as: :get_plans
  uses_routine ShortCode::UrlFor, as: :get_short_code_url

  protected

  def exec(course:, role:, start_at_ntz: nil, end_at_ntz: nil)
    if course.is_concept_coach
      fatal_error(code: :cc_course)
      return
    end

    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_role(role, role_type)
    load_course(course, role_type)
    load_tasks(role, role_type, start_at_ntz, end_at_ntz)
    load_plans(course, start_at_ntz, end_at_ntz) if :teacher == role_type
  end

  def load_plans(course, start_at_ntz, end_at_ntz)
    out = run(:get_plans, owner: course, start_at_ntz: start_at_ntz,
                          end_at_ntz: end_at_ntz, include_trouble_flags: true).outputs
    outputs[:plans] = out[:plans].map do |task_plan|
      {
        id: task_plan.id,
        title: task_plan.title,
        type: task_plan.type,
        description: task_plan.description,
        is_publish_requested: !task_plan.is_draft?,
        published_at: task_plan.published_at,
        publish_last_requested_at: task_plan.publish_last_requested_at,
        publish_job_uuid: task_plan.publish_job_uuid,
        tasking_plans: task_plan.tasking_plans,
        is_trouble: out[:trouble_plan_ids].include?(task_plan.id),
        shareable_url: run(:get_short_code_url, task_plan, suffix: task_plan.title).outputs.url
      }
    end
  end
end
