module Tasks
  class AssignCoursewideTaskPlansToNewPeriod
    lev_routine

    protected
    def exec(period:)
      @existing_period_ids = period.course.periods.flat_map(&:id) - [period.id]

      task_plans_with_matching_tasking_plans_across_periods.each do |task_plan|
        create_tasking_plan(period, task_plan)
      end
    end

    private
    attr_reader :existing_period_ids

    def create_tasking_plan(period, task_plan)
      Models::TaskingPlan.create(target: period.to_model,
                                 opens_at: task_plan.tasking_plans.first.opens_at,
                                 due_at: task_plan.tasking_plans.first.due_at,
                                 tasks_task_plan_id: task_plan.id)
    end

    def task_plans_with_matching_tasking_plans_across_periods
      task_plans_across_periods.reject do |task_plan|
        target_ids = task_plan.tasking_plans.flat_map(&:target_id).uniq.sort
        period_ids = existing_period_ids.uniq.sort
        due_dates = task_plan.tasking_plans.flat_map(&:due_at).uniq
        open_dates = task_plan.tasking_plans.flat_map(&:opens_at).uniq

        target_ids != period_ids || due_dates.size != 1 || open_dates.size != 1
      end
    end

    def task_plans_across_periods
      Models::TaskPlan.joins(:tasking_plans)
                      .preload(:tasking_plans)
                      .where(tasking_plans: {
                        target_id: existing_period_ids,
                        target_type: 'CourseMembership::Models::Period'
                      })
    end
  end
end
