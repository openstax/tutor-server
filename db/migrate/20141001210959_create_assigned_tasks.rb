class CreateAssignedTasks < ActiveRecord::Migration
  def change
    create_table :assigned_tasks do |t|
      t.string :assignee_type
      t.integer :assignee_id
      t.integer :user_id
      t.integer :task_id

      t.timestamps null: false
    end
  end
end
