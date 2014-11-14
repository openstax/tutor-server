class CreateExerciseDefinitionTopics < ActiveRecord::Migration
  def change
    create_table :exercise_definition_topics do |t|
      t.references :exercise_definition, null: false
      t.references :topic, null: false

      t.timestamps null: false
    end

    add_index :exercise_definition_topics, :exercise_definition_id
    add_index :exercise_definition_topics, [:topic_id, :exercise_definition_id], unique: true, name: "index_ed_topics_on_topic_id_and_ed_id"
  end
end
