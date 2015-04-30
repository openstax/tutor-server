class CreateTasksTaskSteps < ActiveRecord::Migration
  def change
    create_table :tasks_task_steps do |t|
      t.references :tasks_task, null: false
      t.references :tasked, polymorphic: true, null: false
      t.integer :number, null: false
      t.datetime :completed_at
      t.integer :group_type, default: 0, null: false

      t.timestamps null: false

      t.index [:tasked_id, :tasked_type], unique: true
      t.index [:tasks_task_id, :number], unique: true
    end

    add_foreign_key :tasks_task_steps, :tasks_tasks, on_update: :cascade, on_delete: :cascade
  end
end
