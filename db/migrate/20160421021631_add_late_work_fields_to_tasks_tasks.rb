class AddLateWorkFieldsToTasksTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :is_late_work_accepted, :boolean, default: false
    add_column :tasks_tasks, :correct_on_time_exercise_steps_count, :integer
    add_column :tasks_tasks, :completed_on_time_exercise_steps_count, :integer
    add_column :tasks_tasks, :completed_on_time_steps_count, :integer

    reversible do |dir|
      dir.up do
        Tasks::Models::Task.preload(task_steps: :tasked).find_each(&:update_step_counts!)
      end
    end
  end
end
