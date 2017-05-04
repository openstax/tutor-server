class AddTaskPlanIsPreviewFlag < ActiveRecord::Migration
  def change
    add_column :tasks_task_plans, :is_preview, :boolean
    change_column_default :tasks_task_plans, :is_preview, false
  end
end
