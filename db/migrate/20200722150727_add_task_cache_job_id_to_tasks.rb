class AddTaskCacheJobIdToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :task_cache_job_id, :integer
  end
end
