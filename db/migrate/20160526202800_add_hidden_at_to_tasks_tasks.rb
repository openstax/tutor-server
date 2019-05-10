class AddHiddenAtToTasksTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasks, :hidden_at, :datetime

    add_index :tasks_tasks, :hidden_at
  end
end
