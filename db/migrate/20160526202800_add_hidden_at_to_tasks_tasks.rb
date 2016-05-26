class AddHiddenAtToTasksTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :hidden_at, :datetime

    add_index :tasks_tasks, :hidden_at
  end
end
