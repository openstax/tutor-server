class ImproveTasksTasksTaskTypeIndexForResearchExport < ActiveRecord::Migration[4.2]
  def change
    remove_index :tasks_tasks, :task_type
    add_index :tasks_tasks, [ :task_type, :created_at ]
  end
end
