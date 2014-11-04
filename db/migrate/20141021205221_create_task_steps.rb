class CreateTaskSteps < ActiveRecord::Migration
  def change
    create_table :task_steps do |t|
      t.references :details, polymorphic: true, null: false
      t.references :task, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :task_steps, [:details_id, :details_type], unique: true
    add_index :task_steps, [:task_id, :number], unique: true
  end
end
