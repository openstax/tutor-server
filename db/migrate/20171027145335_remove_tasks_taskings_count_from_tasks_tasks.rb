class RemoveTasksTaskingsCountFromTasksTasks < ActiveRecord::Migration
  def change
    remove_column :tasks_tasks, :tasks_taskings_count, :integer, null: false, default: 0
  end
end
