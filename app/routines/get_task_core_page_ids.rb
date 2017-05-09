class GetTaskCorePageIds

  # Steps with these group_types determine a task's core pages
  CORE_STEP_GROUP_TYPES = Tasks::Models::TaskStep.group_types
                                                 .values_at(:core_group, :personalized_group)

  lev_routine express_output: :task_id_to_core_page_ids_map

  protected

  # The core page ids exclude spaced practice/personalized pages
  def exec(tasks:)
    loaded_tasks, unloaded_tasks = tasks.partition { |task| task.task_steps.loaded? }

    unloaded_task_steps = Tasks::Models::TaskStep.where(tasks_task_id: unloaded_tasks.map(&:id),
                                                        group_type: CORE_STEP_GROUP_TYPES)
                                                 .pluck(:tasks_task_id, :content_page_id)
                                                 .group_by(&:first)

    task_id_to_core_page_ids_map = {}
    loaded_tasks.each do |task|
      task_steps = task.task_steps.select do |task_step|
        step.core_group? || step.personalized_group?
      end

      task_id_to_core_page_ids_map[task.id] = task_steps.map(&:content_page_id).uniq
    end
    unloaded_tasks.each do |task|
      task_steps = unloaded_task_steps[task.id] || []
      task_id_to_core_page_ids_map[task.id] = task_steps.map(&:second).uniq
    end

    outputs.task_id_to_core_page_ids_map = task_id_to_core_page_ids_map
  end
end
