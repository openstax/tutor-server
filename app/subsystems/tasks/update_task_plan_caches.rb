# Updates the TaskPlan cache fields (step counts), used by the Teacher dashboard NEW flag
class Tasks::UpdateTaskPlanCaches
  lev_routine active_job_enqueue_options: { queue: :dashboard }, transaction: :read_committed

  protected

  def exec(task_plan_ids:, queue: 'dashboard')
    ScoutHelper.ignore!(0.995)

    task_plan_ids = [ task_plan_ids ].flatten

    # Attempt to lock the task_plans; Skip task_plans already locked by someone else
    task_plans = Tasks::Models::TaskPlan
      .where(id: task_plan_ids)
      .lock('FOR NO KEY UPDATE SKIP LOCKED')
      .preload(:tasking_plans)
      .to_a
    locked_task_plan_ids = task_plans.map(&:id)

    # Requeue task_plans that exist but we couldn't lock
    skipped_task_plan_ids = task_plan_ids - locked_task_plan_ids
    unless skipped_task_plan_ids.empty?
      existing_skipped_task_plan_ids = Tasks::Models::TaskPlan.where(
        id: skipped_task_plan_ids
      ).pluck(:id)
      self.class.set(queue: queue.to_sym).perform_later(
        task_plan_ids: existing_skipped_task_plan_ids, queue: queue
      ) unless existing_skipped_task_plan_ids.empty?
    end

    # Stop if we couldn't lock any task_plans at all
    return if task_plans.empty?

    task_plans = task_plans.map(&:update_gradable_step_counts)
    tasking_plans = task_plans.flat_map(&:unarchived_period_tasking_plans)

    # Update the TaskingPlan cache columns (step counts)
    Tasks::Models::TaskingPlan.import tasking_plans, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: Tasks::Models::TaskingPlan::CACHE_COLUMNS
    }

    # Update the TaskPlan cache columns (step counts)
    Tasks::Models::TaskPlan.import task_plans, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: Tasks::Models::TaskPlan::CACHE_COLUMNS
    }
  end
end
