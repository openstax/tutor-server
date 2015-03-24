class CreateTasksLegacyTaskMaps < ActiveRecord::Migration
  def change
    create_table :tasks_legacy_task_maps do |t|
      t.integer :entity_task_id, null: false
      t.integer :task_id, null: false
      t.timestamps null: false

      t.index [:entity_task_id, :task_id], unique: true
      t.index :task_id, unique: true
    end

    add_foreign_key :tasks_legacy_task_maps, :entity_tasks
    add_foreign_key :tasks_legacy_task_maps, :tasks
  end
end
