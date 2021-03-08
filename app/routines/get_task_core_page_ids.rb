class GetTaskCorePageIds

  lev_routine transaction: :read_committed, express_output: :task_id_to_core_page_ids_map

  protected

  # The core page ids exclude spaced practice/personalized pages
  def exec(tasks:)
    loaded_tasks, unloaded_tasks = [ tasks ].flatten.partition { |task| task.task_steps.loaded? }

    unloaded_task_steps = Tasks::Models::TaskStep.where(
      tasks_task_id: unloaded_tasks.map(&:id), is_core: true
    ).order(:number).pluck(:tasks_task_id, :content_page_id).group_by(&:first)

    task_id_to_core_page_ids_map = {}
    loaded_tasks.each do |task|
      task_steps = task.task_steps.filter(&:is_core?)

      task_id_to_core_page_ids_map[task.id] = task_steps.map(&:content_page_id).compact.uniq
    end
    unloaded_tasks.each do |task|
      task_steps = unloaded_task_steps[task.id] || []
      task_id_to_core_page_ids_map[task.id] = task_steps.map(&:second).compact.uniq
    end

    outputs.task_id_to_core_page_ids_map = task_id_to_core_page_ids_map
  end
end
