class CacheIfTaskIsManuallyGradable < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_task_plans, :is_auto_gradable, :boolean
  end
end
