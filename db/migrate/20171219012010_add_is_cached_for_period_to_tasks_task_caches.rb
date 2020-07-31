class AddIsCachedForPeriodToTasksTaskCaches < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_caches, :is_cached_for_period, :boolean

    change_column_null :tasks_task_caches, :is_cached_for_period, false

    add_index :tasks_task_caches, :is_cached_for_period
  end
end
