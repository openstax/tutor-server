class AddTaskSpyColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasks, :spy, :text, default: '{}', null: false
  end
end
