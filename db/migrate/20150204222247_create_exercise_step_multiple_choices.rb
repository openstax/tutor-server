class CreateExerciseStepMultipleChoices < ActiveRecord::Migration
  def change
    create_table :exercise_step_multiple_choices do |t|
      t.integer :answer_id

      t.timestamps null: false
    end
  end
end
