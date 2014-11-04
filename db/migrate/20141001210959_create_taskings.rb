class CreateTaskings < ActiveRecord::Migration
  def change
    create_table :taskings do |t|
      t.references :assignee, polymorphic: true, null: false
      t.references :task, null: false
      t.references :user, null: false
      t.integer :grade_override

      t.timestamps null: false
    end

    add_index :taskings, [:assignee_id, :assignee_type, :task_id], unique: true
    add_index :taskings, [:task_id, :user_id], unique: true
    add_index :taskings, :user_id
  end
end
