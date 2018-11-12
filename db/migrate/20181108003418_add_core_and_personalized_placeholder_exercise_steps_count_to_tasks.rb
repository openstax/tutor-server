class AddCoreAndPersonalizedPlaceholderExerciseStepsCountToTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :core_and_personalized_placeholder_exercise_steps_count, :integer,
               null: false, default: 0

    reversible do |dir|
      dir.up   { BackgroundMigrate.perform_later 'up', 20181112190157 }
      dir.down { BackgroundMigrate.perform_later 'down', 20181112190157 }
    end
  end
end
