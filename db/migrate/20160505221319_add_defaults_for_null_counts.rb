class AddDefaultsForNullCounts < ActiveRecord::Migration
  def up
    Tasks::Models::Task.unscoped.preload(task_steps: :tasked).find_each do |task|
      task.update_step_counts!(validate: false)
    end

    change_column_default :tasks_tasks, :correct_on_time_exercise_steps_count, 0
    change_column_default :tasks_tasks, :completed_on_time_exercise_steps_count, 0
    change_column_default :tasks_tasks, :completed_on_time_steps_count, 0

    change_column_null :tasks_tasks, :correct_on_time_exercise_steps_count, false
    change_column_null :tasks_tasks, :completed_on_time_exercise_steps_count, false
    change_column_null :tasks_tasks, :completed_on_time_steps_count, false
  end

  def down
    change_column_null :tasks_tasks, :correct_on_time_exercise_steps_count, true
    change_column_null :tasks_tasks, :completed_on_time_exercise_steps_count, true
    change_column_null :tasks_tasks, :completed_on_time_steps_count, true

    change_column_default :tasks_tasks, :correct_on_time_exercise_steps_count, nil
    change_column_default :tasks_tasks, :completed_on_time_exercise_steps_count, nil
    change_column_default :tasks_tasks, :completed_on_time_steps_count, nil
  end
end
