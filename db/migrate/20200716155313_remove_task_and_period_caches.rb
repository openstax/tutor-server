class RemoveTaskAndPeriodCaches < ActiveRecord::Migration[5.2]
  def up
    drop_table :tasks_task_caches

    drop_table :tasks_period_caches

    remove_column :tasks_taskings, :course_membership_period_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
