class CreateTasksTaskings < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_taskings do |t|
      t.references :entity_role, null: false, foreign_key: { on_update: :cascade,
                                                             on_delete: :cascade }
      t.references :entity_task, null: false, index: true, foreign_key: { on_update: :cascade,
                                                                          on_delete: :cascade }
      t.references :course_membership_period, index: true, foreign_key: { on_update: :cascade,
                                                                          on_delete: :nullify }

      t.timestamps null: false

      t.index [:entity_role_id, :entity_task_id],
              unique: true, name: 'tasks_taskings_role_id_on_task_id_unique'
    end
  end
end
