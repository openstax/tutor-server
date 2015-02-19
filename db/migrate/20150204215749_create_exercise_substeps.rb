class CreateExerciseSubsteps < ActiveRecord::Migration
  def change
    create_table :exercise_substeps do |t|
      t.references :tasked_exercise, null: false
      t.references :subtasked, polymorphic: true, null: false
      t.integer :number, null: false
      t.datetime :completed_at

      t.timestamps null: false

      t.index [:subtasked_id, :subtasked_type], unique: true
      t.index [:tasked_exercise_id, :number], unique: true
    end

    add_foreign_key :exercise_substeps, :tasked_exercises,
                    on_update: :cascade,  on_delete: :cascade
  end
end
