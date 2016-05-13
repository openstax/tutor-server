class AddMultipartFieldsToTasksTaskedExercise < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_exercises, :is_in_multipart, :boolean, null: false, default: false
    add_column :tasks_tasked_exercises, :question_id, :string

    reversible do |dir|
      dir.up do
        Tasks::Models::TaskedExercise.update_all(
          "question_id = substring(content from '\"questions\":\\[\\{\"id\":(\\d+),')"
        )
      end
    end

    change_column_null :tasks_tasked_exercises, :question_id, false
    add_index :tasks_tasked_exercises, :question_id
  end
end
