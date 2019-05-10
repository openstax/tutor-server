class RemoveTasksTaskingsCountFromTasksTasks < ActiveRecord::Migration[4.2]
  def change
    remove_column :tasks_tasks, :tasks_taskings_count, :integer, null: false, default: 0
  end
end
