class AddIsCoreToTasksTaskSteps < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_task_steps, :is_core, :boolean
    # We still do migrations inline, with the server down, so we can still use rename_column...
    rename_column :tasks_tasks, :core_and_personalized_placeholder_exercise_steps_count,
                                :core_placeholder_exercise_steps_count

    reversible do |dir|
      dir.up   { BackgroundMigrate.perform_later 'up',   20190918184315 }
      dir.down { BackgroundMigrate.perform_later 'down', 20190918184315 }
    end
  end
end
