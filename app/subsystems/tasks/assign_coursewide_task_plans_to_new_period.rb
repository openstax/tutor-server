module Tasks
  class AssignCoursewideTaskPlansToNewPeriod
    lev_routine

    protected
    def exec(period:)
      @existing_period_ids = period.course.periods.flat_map(&:id) - [period.id]

      task_plans_with_matching_tasking_plans_across_periods.each do |task_plan|
        Models::TaskingPlan.create(target: period.to_model,
                                   opens_at: task_plan.tasking_plans.first.opens_at,
                                   due_at: task_plan.tasking_plans.first.due_at,
                                   tasks_task_plan_id: task_plan.id)
      end
    end

    private
    attr_reader :existing_period_ids

    def task_plans_with_matching_tasking_plans_across_periods
      task_plans_across_periods.select { |task_plan|

        assigned_to_all_existing_periods?(task_plan.tasking_plans) &&
          tasking_plans_have_same_dates?(task_plan)

      }
    end

    def assigned_to_all_existing_periods?(tasking_plans)
      tasking_plans.flat_map(&:target_id).sort == existing_period_ids.sort
    end

    def tasking_plans_have_same_dates?(task_plan)
      task_plan.tasking_plans.flat_map(&:due_at).uniq.one? &&
        task_plan.tasking_plans.flat_map(&:opens_at).uniq.one?
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
