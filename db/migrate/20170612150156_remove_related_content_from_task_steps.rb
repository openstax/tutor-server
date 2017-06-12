class RemoveRelatedContentFromTaskSteps < ActiveRecord::Migration
  def change
    remove_column :tasks_task_steps, :related_content, :text, null: false, default: "[]"
  end
end
