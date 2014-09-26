class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :taskable, polymorphic: true, null: false
      t.integer :user_id, null: false
      t.integer :task_plan_id, null: true
      t.datetime :opens_at
      t.datetime :due_at
      t.boolean :is_shared
      t.references :details, polymorphic: true, null: false

      t.timestamps null: false
    end

    add_index :tasks, [:taskable_id, :taskable_type]
    add_index :tasks, :task_plan_id
    add_index :tasks, :user_id
    add_index :tasks, :opens_at
    add_index :tasks, :due_at
    add_index :tasks, [:details_id, :details_type]
  end
end
