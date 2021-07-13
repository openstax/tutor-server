class AddFragmentIndexToTasksTaskSteps < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_steps, :fragment_index, :integer
  end
end
