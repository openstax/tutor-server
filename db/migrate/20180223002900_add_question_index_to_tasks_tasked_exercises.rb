class AddQuestionIndexToTasksTaskedExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasked_exercises, :question_index, :integer

    reversible do |dir|
      dir.up   { BackgroundMigrate.perform_later 'up',   20180219163045 }
      dir.down { BackgroundMigrate.call          'down', 20180219163045 }
    end
  end
end
