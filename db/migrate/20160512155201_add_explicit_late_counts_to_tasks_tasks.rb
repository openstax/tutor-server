class AddExplicitLateCountsToTasksTasks < ActiveRecord::Migration[4.2]
  def change
    remove_column :tasks_tasks, :is_late_work_accepted
    add_column :tasks_tasks, :accepted_late_at, :datetime
    add_column :tasks_tasks, :correct_accepted_late_exercise_steps_count, :integer, null: false, default: 0
    add_column :tasks_tasks, :completed_accepted_late_exercise_steps_count, :integer, null: false, default: 0
    add_column :tasks_tasks, :completed_accepted_late_steps_count, :integer, null: false, default: 0
  end
end
