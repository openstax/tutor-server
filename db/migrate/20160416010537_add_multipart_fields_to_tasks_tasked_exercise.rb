class AddMultipartFieldsToTasksTaskedExercise < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_exercises, :is_in_multipart, :boolean
    add_column :tasks_tasked_exercises, :question_id, :string

    add_index :tasks_tasked_exercises, :question_id
  end
end
