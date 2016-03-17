class AddTaskPlanFeedback < ActiveRecord::Migration
  def change
    add_column :tasks_task_plans, :is_feedback_immediate, :bool
  end
end
