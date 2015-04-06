class AddPathToTasksTaskedReadings < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_readings, :path, :string
  end
end
