class CreateTaskPlans < ActiveRecord::Migration
  def change
    create_table :task_plans do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :assistant, null: false
      t.text :configuration, null: false
      t.datetime :assign_after, null: false
      t.datetime :assigned_at
      t.boolean :is_ready

      t.timestamps null: false
    end

    add_index :task_plans, [:owner_id, :owner_type]
    add_index :task_plans, [:assign_after, :is_ready]
    add_index :task_plans, :assistant
    add_index :task_plans, :assigned_at
  end
end
