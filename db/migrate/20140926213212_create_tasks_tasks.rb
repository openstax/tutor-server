class CreateTasksTasks < ActiveRecord::Migration
  def change
    create_table :tasks_tasks do |t|
      t.references :tasks_task_plan
      t.references :entity_task
      t.string :task_type, null: false
      t.string :title, null: false
      t.datetime :opens_at, null: false
      t.datetime :due_at
      t.integer :tasks_taskings_count, null: false, default: 0
      t.text :spaced_practice_algorithm, null: false

      t.timestamps null: false

      t.index :tasks_task_plan_id
      t.index :entity_task_id
      t.index :task_type
      t.index [:due_at, :opens_at]
    end

    add_foreign_key :tasks_tasks, :tasks_task_plans,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :tasks_tasks, :entity_tasks,
                    on_update: :cascade, on_delete: :cascade
  end
end
