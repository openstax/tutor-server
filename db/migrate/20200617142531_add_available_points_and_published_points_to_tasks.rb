class AddAvailablePointsAndPublishedPointsToTasks < ActiveRecord::Migration[5.2]
  def change
    rename_column :tasks_tasked_exercises, :published_points, :published_grader_points

    add_column :tasks_tasks, :available_points, :float
    add_column :tasks_tasks, :published_points_before_due, :float
    add_column :tasks_tasks, :published_points_after_due, :float
    add_column :tasks_tasks, :is_provisional_score_before_due, :boolean
    add_column :tasks_tasks, :is_provisional_score_after_due, :boolean

    reversible do |dir|
      dir.up   { BackgroundMigrate.perform_later 'up',   20200617142820 }
      dir.down { BackgroundMigrate.perform_later 'down', 20200617142820 }
    end
  end
end
