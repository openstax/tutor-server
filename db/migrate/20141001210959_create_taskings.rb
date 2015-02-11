class CreateTaskings < ActiveRecord::Migration
  def change
    create_table :taskings do |t|
      t.references :taskee, polymorphic: true, null: false
      t.references :task, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :taskings, [:taskee_id, :taskee_type, :task_id], unique: true
    add_index :taskings, [:task_id, :user_id], unique: true
    add_index :taskings, :user_id

    add_foreign_key :taskings, :tasks, on_update: :cascade,
                                       on_delete: :cascade
    add_foreign_key :taskings, :users, on_update: :cascade,
                                       on_delete: :cascade
  end
end
