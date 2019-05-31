class AddCoreAndPersonalizedPlaceholderExerciseStepsCountToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasks, :core_and_personalized_placeholder_exercise_steps_count, :integer

    reversible do |dir|
      dir.up   do
        change_column_default :tasks_tasks,
                              :core_and_personalized_placeholder_exercise_steps_count,
                              0

        BackgroundMigrate.perform_later 'up', 20181112190157
      end
      dir.down { BackgroundMigrate.perform_later 'down', 20181112190157 }
    end
  end
end
