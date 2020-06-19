class AddWrqCountGradableStepCountAndUngradedStepCount < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :gradable_step_count, :integer, default: 0, null: false

    add_column :tasks_tasking_plans, :gradable_step_count, :integer, default: 0, null: false
    add_column :tasks_tasking_plans, :ungraded_step_count, :integer, default: 0, null: false

    add_column :tasks_task_plans, :wrq_count, :integer, default: 0, null: false
    add_column :tasks_task_plans, :gradable_step_count, :integer, default: 0, null: false
  end
end
