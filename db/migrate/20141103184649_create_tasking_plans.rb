class CreateTaskingPlans < ActiveRecord::Migration
  def change
    create_table :tasking_plans do |t|
      t.references :target, polymorphic: true, null: false
      t.references :task_plan, null: false

      t.timestamps null: false
    end

    add_index :tasking_plans,
              [:target_id, :target_type, :task_plan_id], unique: true,
              name: 'index_tasking_plans_on_t_id_and_t_type_and_t_p_id'
    add_index :tasking_plans, :task_plan_id
  end
end
