class CreateExerciseSteps < ActiveRecord::Migration
  def change
    create_table :exercise_steps do |t|
      t.references :exercise, null: false
      t.references :step, polymorphic: true, null: false
      t.integer :number, null: false
      t.datetime :completed_at

      t.timestamps null: false
    end

    add_index :exercise_steps, [:step_id, :step_type], unique: true
    add_index :exercise_steps, [:exercise_id, :number], unique: true

    add_foreign_key :exercise_steps, :exercises, on_update: :cascade,
                                                 on_delete: :cascade
  end
end
