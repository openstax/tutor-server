class AddTaskPlanDemoFlag < ActiveRecord::Migration
  def change
    add_column :tasks_task_plans, :is_demo, :boolean
    change_column_default :tasks_task_plans, :is_demo, false
  end
end
