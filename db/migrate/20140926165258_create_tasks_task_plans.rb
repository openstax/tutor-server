class CreateTasksTaskPlans < ActiveRecord::Migration
  def change
    create_table :tasks_task_plans do |t|
      t.references :tasks_assistant, null: false
      t.references :owner, polymorphic: true, null: false
      t.string :title
      t.string :type, null: false
      t.text :settings, null: false
      t.datetime :opens_at, null: false
      t.datetime :due_at
      t.datetime :published_at
      t.timestamps null: false

      t.index [:owner_id, :owner_type]
      t.index [:due_at, :opens_at]
      t.index :tasks_assistant_id
    end

    add_foreign_key :tasks_task_plans, :tasks_assistants, 
                    on_update: :cascade, on_delete: :cascade
  end
end
