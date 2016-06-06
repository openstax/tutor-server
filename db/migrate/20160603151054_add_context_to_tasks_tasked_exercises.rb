class AddContextToTasksTaskedExercises < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_exercises, :context, :text
  end
end
