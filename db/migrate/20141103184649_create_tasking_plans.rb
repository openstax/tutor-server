class CreateTaskingPlans < ActiveRecord::Migration
  def change
    create_table :tasking_plans do |t|
      t.references :target, polymorphic: true, null: false
      t.references :task_plan, null: false

      t.timestamps null: false

      t.index [:target_id, :target_type, :task_plan_id], unique: true,
              name: 'index_tasking_plans_on_t_id_and_t_type_and_t_p_id'
      t.index :task_plan_id
    end

    add_foreign_key :tasking_plans, :task_plans, on_update: :cascade,
                                                 on_delete: :cascade
  end
end
