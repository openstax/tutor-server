module Tasks
  class AssignCoursewideTaskPlansToNewPeriod
    lev_routine

    protected

    def exec(period:)
      @existing_period_ids = period.course.periods.flat_map(&:id) - [period.id]

      task_plans_with_matching_tasking_plans_across_periods.each do |task_plan|
        base_tasking_plan = task_plan.tasking_plans.first

        Tasks::Models::TaskingPlan.create(
          target: period,
          opens_at: base_tasking_plan.opens_at,
          due_at: base_tasking_plan.due_at,
          closes_at: base_tasking_plan.closes_at,
          tasks_task_plan_id: task_plan.id
        )
      end
    end

    private
    attr_reader :existing_period_ids

    def task_plans_with_matching_tasking_plans_across_periods
      task_plans_across_periods.select do |task_plan|
        assigned_to_all_existing_periods?(task_plan.tasking_plans) &&
          tasking_plans_have_same_dates?(task_plan)
      end
    end

    def assigned_to_all_existing_periods?(tasking_plans)
      tasking_plans.flat_map(&:target_id).sort == existing_period_ids.sort
    end

    def tasking_plans_have_same_dates?(task_plan)
      task_plan.tasking_plans.flat_map(&:due_at).uniq.size == 1 &&
        task_plan.tasking_plans.flat_map(&:opens_at).uniq.size == 1 &&
          task_plan.tasking_plans.flat_map(&:closes_at).uniq.size == 1
    end

    def task_plans_across_periods
      Tasks::Models::TaskPlan.joins(:tasking_plans).where(
        tasking_plans: {
          target_id: existing_period_ids, target_type: 'CourseMembership::Models::Period'
        }
      ).preload(:tasking_plans).to_a
    end
  end
end
