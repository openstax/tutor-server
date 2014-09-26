class CreateTaskPlans < ActiveRecord::Migration
  def change
    create_table :task_plans do |t|
      t.references :owner, polymorphic: true, null: false
      t.datetime :assign_after
      t.datetime :opens_at
      t.datetime :due_at
      t.boolean :is_shared, null: false
      t.references :details, polymorphic: true, null: false

      t.timestamps null: false
    end

    add_index :task_plans, :assign_after
    add_index :task_plans, [:owner_id, :owner_type]
    add_index :task_plans, [:details_id, :details_type], unique: true
  end
end
