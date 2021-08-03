class AddAttemptNumberToTasksTaskedExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasked_exercises, :attempt_number, :integer
    change_column_default :tasks_tasked_exercises, :attempt_number, 0
  end
end
