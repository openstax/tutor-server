class AddTasksTasksForeignKeyToContentEcosystems < ActiveRecord::Migration
  def change
    add_foreign_key :tasks_tasks, :content_ecosystems, on_update: :cascade, on_delete: :cascade
  end
end
