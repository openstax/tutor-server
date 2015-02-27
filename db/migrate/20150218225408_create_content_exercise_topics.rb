class CreateContentExerciseTopics < ActiveRecord::Migration
  def change
    create_table :content_exercise_topics do |t|
      t.references :content_exercise, null: false
      t.references :content_topic, null: false
      t.integer :number, null: false

      t.timestamps null: false

      t.index [:content_topic_id, :content_exercise_id], unique: true, name: 'content_exercise_topic_ce_unique'
      t.index [:content_exercise_id, :number], unique: true, name: 'content_exercise_ce_number_unique'
    end

    add_foreign_key :content_exercise_topics, :content_exercises, on_update: :cascade,
                                                                  on_delete: :cascade
    add_foreign_key :content_exercise_topics, :content_topics, on_update: :cascade,
                                                               on_delete: :cascade
  end
end
