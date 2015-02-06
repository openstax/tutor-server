class CreateTaskPlans < ActiveRecord::Migration
  def change
    create_table :task_plans do |t|
      t.references :assistant, null: false
      t.references :owner, polymorphic: true, null: false
      t.string :title
      t.string :type, null: false
      t.text :configuration, null: false
      t.datetime :opens_at, null: false
      t.datetime :due_at

      t.timestamps null: false
    end

    add_index :task_plans, [:owner_id, :owner_type]
    add_index :task_plans, [:due_at, :opens_at]
    add_index :task_plans, :assistant_id

    add_foreign_key :task_plans, :assistants, on_update: :cascade,
                                              on_delete: :cascade
  end
end
