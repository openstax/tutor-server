# Updates the Task cache fields (step counts), used by several parts of Tutor
class Tasks::UpdateTaskCaches
  lev_routine active_job_enqueue_options: { queue: :dashboard }, transaction: :read_committed

  uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map

  protected

  def exec(tasks: nil, task_ids: nil, queue: 'dashboard')
    raise(ArgumentError, 'Either tasks or task_ids must be provided') if tasks.nil? && task_ids.nil?

    ScoutHelper.ignore!(0.995)

    if tasks.nil?
      task_ids = [ task_ids ].flatten

      # Attempt to lock the tasks; Skip tasks already locked by someone else
      tasks = Tasks::Models::Task
        .where(id: task_ids)
        .lock('FOR NO KEY UPDATE SKIP LOCKED')
        .preload(:course, task_steps: :tasked, task_plan: [ :course, :extensions ])
        .to_a
      locked_task_ids = tasks.map(&:id)

      # Requeue tasks that exist but we couldn't lock
      skipped_task_ids = task_ids - locked_task_ids
      unless skipped_task_ids.empty?
        existing_skipped_task_ids = Tasks::Models::Task.where(id: skipped_task_ids).pluck(:id)
        self.class.set(queue: queue.to_sym).perform_later(
          task_ids: existing_skipped_task_ids, queue: queue
        ) unless existing_skipped_task_ids.empty?
      end

      # Stop if we couldn't lock any tasks at all
      return if tasks.empty?
    else
      tasks = [ tasks ].flatten
    end

    tasks = tasks.map(&:update_cached_attributes)

    # Update the Task cache columns (step counts)
    Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: Tasks::Models::Task::CACHE_COLUMNS
    }

    # Update task_plan step counts
    # Normally this is done in the task's after_update but upserting does not trigger that
    task_plan_ids = tasks.map(&:tasks_task_plan_id).compact.uniq
    Tasks::UpdateTaskPlanCaches.call(
      task_plan_ids: task_plan_ids, queue: queue
    ) unless task_plan_ids.empty?
  end
end
