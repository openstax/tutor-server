class AddDefaultsForNullCounts < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Tasks::Models::Task.preload(task_steps: :tasked).find_each(&:update_step_counts!)
      end
    end

    change_column_null :tasks_tasks, :correct_on_time_exercise_steps_count, false
    change_column_null :tasks_tasks, :completed_on_time_exercise_steps_count, false
    change_column_null :tasks_tasks, :completed_on_time_steps_count, false

    change_column_default :tasks_tasks, :correct_on_time_exercise_steps_count, 0
    change_column_default :tasks_tasks, :completed_on_time_exercise_steps_count, 0
    change_column_default :tasks_tasks, :completed_on_time_steps_count, 0
  end
end
