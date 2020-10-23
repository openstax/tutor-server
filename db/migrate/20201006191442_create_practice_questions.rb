class CreatePracticeQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks_practice_questions do |t|
      t.references :tasks_tasked_exercise, null: false, foreign_key: { on_update: :cascade,
                                                                       on_delete: :cascade },
                                                        index: true
      t.references :content_exercise, null: false,
                                      foreign_key: { on_update: :cascade,
                                                     on_delete: :cascade },
                                      index: true
      t.references :entity_role, null: false, foreign_key: { on_update: :cascade,
                                                             on_delete: :cascade }
      t.timestamps
      t.index ['entity_role_id', 'content_exercise_id'], name: 'index_question_on_role_and_exercise', unique: true

    end
  end
end
