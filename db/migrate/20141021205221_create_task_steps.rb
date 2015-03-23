class CreateTaskSteps < ActiveRecord::Migration
  def change
    create_table :task_steps do |t|
      t.references :task, null: false
      t.references :tasked, polymorphic: true, null: false
      t.integer :number, null: false
      t.datetime :completed_at
      t.string :group_name, null: false

      t.timestamps null: false

      t.index [:tasked_id, :tasked_type], unique: true
      t.index [:task_id, :number], unique: true
    end

    add_foreign_key :task_steps, :tasks, on_update: :cascade,
                                         on_delete: :cascade
  end
end
