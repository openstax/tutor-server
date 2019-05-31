class CreateTasksTaskingPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_tasking_plans do |t|
      t.references :target, polymorphic: true, null: false
      t.references :tasks_task_plan, null: false, index: true,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.datetime :opens_at, null: false
      t.datetime :due_at, null: false

      t.timestamps null: false

      t.index [:target_id, :target_type, :tasks_task_plan_id], unique: true,
              name: 'index_tasking_plans_on_t_id_and_t_type_and_t_p_id'
      t.index [:due_at, :opens_at]
    end
  end
end
