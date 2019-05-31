class AddTaskPlanFeedback < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_plans, :is_feedback_immediate, :bool
  end
end
