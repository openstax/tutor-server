class RemoveEntityTasks < ActiveRecord::Migration[4.2]
  def up
    add_column :tasks_taskings, :tasks_task_id, :integer
    add_column :tasks_concept_coach_tasks, :tasks_task_id, :integer

    Tasks::Models::Tasking.unscoped.update_all(
      'tasks_task_id = tasks_tasks.id
       FROM tasks_tasks
       WHERE tasks_tasks.entity_task_id = tasks_taskings.entity_task_id'
    )

    Tasks::Models::ConceptCoachTask.unscoped.update_all(
      'tasks_task_id = tasks_tasks.id
       FROM tasks_tasks
       WHERE tasks_tasks.entity_task_id = tasks_concept_coach_tasks.entity_task_id'
    )

    change_column_null :tasks_taskings, :tasks_task_id, false
    change_column_null :tasks_concept_coach_tasks, :tasks_task_id, false

    add_index :tasks_taskings, [:tasks_task_id, :entity_role_id], unique: true
    add_index :tasks_taskings, :entity_role_id
    add_index :tasks_concept_coach_tasks, :tasks_task_id, unique: true

    add_foreign_key :tasks_taskings, :tasks_tasks
    add_foreign_key :tasks_concept_coach_tasks, :tasks_tasks

    remove_column :tasks_taskings, :entity_task_id
    remove_column :tasks_concept_coach_tasks, :entity_task_id
    remove_column :tasks_tasks, :entity_task_id

    drop_table :entity_tasks
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
