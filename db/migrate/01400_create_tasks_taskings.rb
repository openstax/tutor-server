class CreateTasksTaskings < ActiveRecord::Migration
  def change
    create_table :tasks_taskings do |t|
      t.integer :entity_role_id, null: false
      t.integer :entity_task_id, null: false
      t.timestamps null: false

      t.index [:entity_role_id, :entity_task_id], unique: true, name: ['tasks_taskings_role_id_on_task_id_unique']
      t.index :entity_task_id
    end

    add_foreign_key :tasks_taskings, :entity_roles
    add_foreign_key :tasks_taskings, :entity_tasks
  end
end
