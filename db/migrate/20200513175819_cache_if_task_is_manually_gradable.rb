class CacheIfTaskIsManuallyGradable < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_task_plans, :ungraded_step_count, :integer, null: false, default: 0
    add_column :tasks_tasks, :ungraded_step_count, :integer, null: false, default: 0
  end
end
