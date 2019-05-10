class AddTaskPlanIsPreviewFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_plans, :is_preview, :boolean
    change_column_default :tasks_task_plans, :is_preview, false
  end
end
