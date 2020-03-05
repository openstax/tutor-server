class AddPageIdsToTasksTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :page_ids, :integer, array: true, default: [], null: false
  end
end
