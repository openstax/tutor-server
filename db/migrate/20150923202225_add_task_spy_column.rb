class AddTaskSpyColumn < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :spy, :hstore
  end
end
