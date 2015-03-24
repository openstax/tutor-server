class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :task_plan
      t.string :task_type, null: false
      t.string :title, null: false
      t.datetime :opens_at, null: false
      t.datetime :due_at
      t.integer :taskings_count, null: false, default: 0

      t.timestamps null: false

      t.index :task_plan_id
      t.index :task_type
      t.index [:due_at, :opens_at]
    end

    add_foreign_key :tasks, :task_plans, on_update: :cascade,
                                         on_delete: :cascade
  end
end
