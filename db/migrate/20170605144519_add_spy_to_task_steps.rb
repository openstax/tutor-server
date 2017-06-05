class AddSpyToTaskSteps < ActiveRecord::Migration
  def change
    add_column :tasks_task_steps, :spy, :text, null: false, default: '{}'
  end
end
