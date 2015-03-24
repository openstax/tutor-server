class AddTaskStepPageId < ActiveRecord::Migration
  def change
    add_column :task_steps, :page_id, :integer
  end
end
