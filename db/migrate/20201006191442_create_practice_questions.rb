class CreatePracticeQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks_practice_questions do |t|
      t.integer :exercise_number, null: false
      t.integer :exercise_version, null: false
      t.integer :tasked_exercise_id, null: false
      t.references :entity_role, null: false, foreign_key: { on_update: :cascade,
                                                             on_delete: :cascade }
      t.timestamps
      t.index ['entity_role_id', 'exercise_version', 'exercise_number'], name: 'index_question_on_exercise_and_role', unique: true
    end
  end
end
