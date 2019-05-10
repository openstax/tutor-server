class AddDeletedAtToTaskModels < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_plans, :deleted_at, :datetime
    add_column :tasks_tasking_plans, :deleted_at, :datetime
    add_column :tasks_tasks, :deleted_at, :datetime
    add_column :tasks_taskings, :deleted_at, :datetime
    add_column :tasks_task_steps, :deleted_at, :datetime
    add_column :tasks_tasked_readings, :deleted_at, :datetime
    add_column :tasks_tasked_exercises, :deleted_at, :datetime
    add_column :tasks_tasked_videos, :deleted_at, :datetime
    add_column :tasks_tasked_interactives, :deleted_at, :datetime
    add_column :tasks_tasked_external_urls, :deleted_at, :datetime
    add_column :tasks_tasked_placeholders, :deleted_at, :datetime
    add_column :tasks_concept_coach_tasks, :deleted_at, :datetime

    add_index :tasks_task_plans, :deleted_at
    add_index :tasks_tasking_plans, :deleted_at
    add_index :tasks_tasks, :deleted_at
    add_index :tasks_taskings, :deleted_at
    add_index :tasks_task_steps, :deleted_at
    add_index :tasks_tasked_readings, :deleted_at
    add_index :tasks_tasked_exercises, :deleted_at
    add_index :tasks_tasked_videos, :deleted_at
    add_index :tasks_tasked_interactives, :deleted_at
    add_index :tasks_tasked_external_urls, :deleted_at
    add_index :tasks_tasked_placeholders, :deleted_at
    add_index :tasks_concept_coach_tasks, :deleted_at
  end
end
