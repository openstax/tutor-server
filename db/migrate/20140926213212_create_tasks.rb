class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :details, polymorphic: true, null: false
      t.references :task_plan
      t.integer :assigned_tasks_count, null: false, default: 0
      t.string :title, null: false
      t.datetime :opens_at
      t.datetime :due_at

      t.timestamps null: false
    end

    add_index :tasks, [:details_id, :details_type]
    add_index :tasks, :task_plan_id
    add_index :tasks, :title
    add_index :tasks, :opens_at
    add_index :tasks, :due_at
  end
end
