class AddIsCachedForPeriodToTasksTaskCaches < ActiveRecord::Migration
  def change
    add_column :tasks_task_caches, :is_cached_for_period, :boolean

    Tasks::Models::TaskCache.update_all(is_cached_for_period: true)

    change_column_null :tasks_task_caches, :is_cached_for_period, false

    add_index :tasks_task_caches, :is_cached_for_period
  end
end
