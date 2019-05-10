class AddDefaultsForNullCounts < ActiveRecord::Migration[4.2]
  def up
    Tasks::Models::Task.unscoped.find_each(&:touch)

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
