class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :task_plan, null: false
      t.string :title, null: false
      t.datetime :opens_at, null: false
      t.datetime :due_at
      t.datetime :closes_at
      t.integer :taskings_count, null: false, default: 0

      t.timestamps null: false
    end

    add_index :tasks, :task_plan_id
    add_index :tasks, :title
    add_index :tasks, [:closes_at, :opens_at]
    add_index :tasks, [:due_at, :opens_at]
    add_index :tasks, :opens_at
  end
end
