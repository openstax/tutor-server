class AddLastWorkedAtToTasksTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :last_worked_at, :datetime
    add_index :tasks_tasks, :last_worked_at
  end
end
