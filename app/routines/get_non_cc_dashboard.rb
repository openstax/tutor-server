class GetNonCcDashboard
  include DashboardRoutineMethods

  lev_routine outputs: { plans: :_self },
              uses: { name: GetCourseTaskPlans, as: :get_plans }

  protected

  def exec(course:, role:)
    if course.is_concept_coach
      fatal_error(code: :cc_course)
      return
    end

    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_role(role, role_type)
    load_course(course, role_type)
    load_tasks(role, role_type)
    load_plans(course) if :teacher == role_type
  end

  def load_plans(course)
    plans_result = run(:get_plans, course: course, include_trouble_flags: true)
    set(plans: plans_result.plans.map do |task_plan|
      {
        id: task_plan.id,
        title: task_plan.title,
        type: task_plan.type,
        is_publish_requested: task_plan.is_publish_requested?,
        published_at: task_plan.published_at,
        publish_last_requested_at: task_plan.publish_last_requested_at,
        publish_job_uuid: task_plan.publish_job_uuid,
        tasking_plans: task_plan.tasking_plans,
        is_trouble: plans_result.trouble_plan_ids.include?(task_plan.id)
      }
    end)
  end
end
