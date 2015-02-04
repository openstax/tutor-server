class CreateExerciseStepFreeResponses < ActiveRecord::Migration
  def change
    create_table :exercise_step_free_responses do |t|
      t.timestamps null: false
    end
  end
end
