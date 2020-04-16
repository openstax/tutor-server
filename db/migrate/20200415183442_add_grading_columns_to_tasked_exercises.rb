class AddGradingColumnsToTaskedExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasked_exercises, :grader_points, :float
    add_column :tasks_tasked_exercises, :grader_comments, :float
    add_column :tasks_tasked_exercises, :manually_graded_at, :datetime
  end
end
