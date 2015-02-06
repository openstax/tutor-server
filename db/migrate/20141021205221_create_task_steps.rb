class CreateTaskSteps < ActiveRecord::Migration
  def change
    create_table :task_steps do |t|
      t.references :task, null: false
      t.references :step, polymorphic: true, null: false
      t.integer :number, null: false
      t.string :title, null: false
      t.string :url, null: false
      t.text :content, null: false
      t.datetime :completed_at

      t.timestamps null: false
    end

    add_index :task_steps, [:step_id, :step_type], unique: true
    add_index :task_steps, [:task_id, :number], unique: true

    add_foreign_key :task_steps, :tasks, on_update: :cascade,
                                         on_delete: :cascade
  end
end
