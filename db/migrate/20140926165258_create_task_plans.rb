class CreateTaskPlans < ActiveRecord::Migration
  def change
    create_table :task_plans do |t|
      t.references :details, polymorphic: true, null: false
      t.references :owner, polymorphic: true, null: false
      t.string :title, null: false
      t.datetime :opens_at
      t.datetime :due_at
      t.datetime :assign_after

      t.timestamps null: false
    end

    add_index :task_plans, [:details_id, :details_type], unique: true
    add_index :task_plans, [:owner_id, :owner_type]
    add_index :task_plans, :title
    add_index :task_plans, :opens_at
    add_index :task_plans, :due_at
    add_index :task_plans, :assign_after
  end
end
