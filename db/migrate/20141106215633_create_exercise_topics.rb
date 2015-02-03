class CreateExerciseTopics < ActiveRecord::Migration
  def change
    create_table :exercise_topics do |t|
      t.references :exercise, null: false
      t.references :topic, null: false

      t.timestamps null: false
    end

    add_index :exercise_topics, [:exercise_id, :topic_id], unique: true
    add_index :exercise_topics, :topic_id
  end
end
