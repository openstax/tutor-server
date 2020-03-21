class AddQuestionIndexToTasksTaskedExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasked_exercises, :question_index, :integer, null: false
  end
end
