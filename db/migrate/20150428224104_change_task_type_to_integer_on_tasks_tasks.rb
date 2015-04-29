class ChangeTaskTypeToIntegerOnTasksTasks < ActiveRecord::Migration
  def change
    change_column :tasks_tasks, :task_type, 'integer USING CAST(task_type AS integer)'
  end
end
