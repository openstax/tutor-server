class CreateTasksTaskingPlans < ActiveRecord::Migration
  def change
    create_table :tasks_tasking_plans do |t|
      t.references :target, polymorphic: true, null: false
      t.references :tasks_task_plan, null: false
      t.datetime :opens_at
      t.datetime :due_at

      t.timestamps null: false

      t.index [:target_id, :target_type, :tasks_task_plan_id], unique: true,
              name: 'index_tasking_plans_on_t_id_and_t_type_and_t_p_id'
      t.index [:due_at, :opens_at]
      t.index :tasks_task_plan_id
    end

    add_foreign_key :tasks_tasking_plans, :tasks_task_plans,
                    on_update: :cascade, on_delete: :cascade
  end
end
