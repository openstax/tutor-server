class AddFirstAndLastPublishedAtToTaskPlans < ActiveRecord::Migration
  def change
    rename_column :tasks_task_plans, :published_at, :first_published_at
    add_column :tasks_task_plans, :last_published_at, :datetime

    reversible do |dir|
      dir.up do
        Tasks::Models::TaskPlan.unscoped.update_all(
          'last_published_at = GREATEST(first_published_at, publish_last_requested_at)'
        )
      end
    end
  end
end
