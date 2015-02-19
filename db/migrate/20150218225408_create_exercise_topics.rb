class CreateExerciseTopics < ActiveRecord::Migration
  def change
    create_table :exercise_topics do |t|
      t.references :exercise, null: false
      t.references :topic, null: false
      t.integer :number, null: false

      t.timestamps null: false

      t.index [:topic_id, :exercise_id], unique: true
      t.index [:exercise_id, :number], unique: true
    end

    add_foreign_key :exercise_topics, :exercises, on_update: :cascade,
                                                  on_delete: :cascade
    add_foreign_key :exercise_topics, :topics, on_update: :cascade,
                                               on_delete: :cascade
  end
end
