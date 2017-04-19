class AddDatetimeIndicesToTasksTaskSteps < ActiveRecord::Migration
  def change
    add_index :tasks_task_steps, :first_completed_at
    add_index :tasks_task_steps, :last_completed_at
  end
end
