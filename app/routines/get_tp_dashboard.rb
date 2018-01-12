class GetTpDashboard

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
    load_research_surveys(course, role) if :student == role_type
    load_tasks(role, role_type, start_at_ntz, end_at_ntz)
    load_plans(course, start_at_ntz, end_at_ntz) if :teacher == role_type
  end

  def load_research_surveys(course, role)
    surveys = role.student.research_surveys
                .preload(:survey_plan)
                .where(completed_at: nil, hidden_at: nil)
    outputs.research_surveys = surveys if surveys.any?
  end

  def load_plans(course, start_at_ntz, end_at_ntz, current_time = Time.current)
    result = run(:get_plans, owner: course,
                             start_at_ntz: start_at_ntz,
                             end_at_ntz: end_at_ntz).outputs
    task_plan_ids = result.plans.map(&:id)
    period_caches_by_task_plan_id = Tasks::Models::PeriodCache
      .select([ :tasks_task_plan_id, :due_at, :student_ids, :as_toc ])
      .joins(:task_plan)
      .where(task_plan: { id: task_plan_ids })
      .where(
        <<-WHERE_SQL.strip_heredoc
          "tasks_period_caches"."content_ecosystem_id" = "tasks_task_plans"."content_ecosystem_id"
        WHERE_SQL
      )
      .group_by(&:tasks_task_plan_id)

    outputs.plans = result.plans.map do |task_plan|
      period_caches = period_caches_by_task_plan_id[task_plan.id] || []
      total_students = period_caches.flat_map { |pc| pc.student_ids }.uniq.size
      pgs = period_caches.flat_map do |period_cache|
        period_cache.as_toc[:books].flat_map do |bk|
          bk[:chapters].flat_map do |ch|
            ch[:pages].reject do |pg|
              pg[:num_assigned_exercises] == 0 && pg[:num_assigned_placeholders] == 0
            end.map { |page| page.merge due_at: period_cache.due_at }
          end
        end
      end
      not_due_pgs, due_pgs = pgs.partition { |pg| pg[:due_at].nil? || pg[:due_at] > current_time }

      task_plan.attributes.symbolize_keys.except(:is_draft, :is_publishing, :is_published).merge(
        is_draft?: task_plan.is_draft?,
        is_publishing?: task_plan.is_publishing?,
        is_published?: task_plan.is_published?,
        is_trouble: get_is_trouble(due_pgs, total_students, true) ||
                    get_is_trouble(not_due_pgs, total_students, false),
        shareable_url: run(:get_short_code_url, task_plan, suffix: task_plan.title).outputs.url,
        tasking_plans: task_plan.tasking_plans
      )
    end
  end

  def get_is_trouble(pgs, total_students, past_due)
    pgs.group_by { |pg| pg[:book_location] }.any? do |book_location, pgs|
      num_students = pgs.flat_map { |pg| pg[:student_ids] }.uniq.size
      next false if num_students < 0.25 * total_students

      num_assigned = pgs.map do |pg|
        pg[:num_assigned_exercises] + pg[:num_assigned_placeholders]
      end.reduce(0, :+)
      num_completed = pgs.map { |pg| pg[:num_completed_exercises] }.reduce(0, :+)
      next past_due if num_completed < 0.5 * num_assigned

      num_correct = pgs.map { |pg| pg[:num_correct_exercises] }.reduce(0, :+)
      num_correct < 0.5 * num_completed
    end
  end

end
