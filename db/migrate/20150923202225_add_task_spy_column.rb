class AddTaskSpyColumn < ActiveRecord::Migration
  def change
    # needed because this is the first use of hstore
    # will be skipped if the DB already happens to have hstore enabled
    enable_extension "hstore"
    add_column :tasks_tasks, :spy, :hstore
  end
end
