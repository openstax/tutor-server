class AddContextToTasksTaskedExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasked_exercises, :context, :text
  end
end
