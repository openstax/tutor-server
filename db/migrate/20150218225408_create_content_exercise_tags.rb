class CreateContentExerciseTags < ActiveRecord::Migration
  def change
    create_table :content_exercise_tags do |t|
      t.references :content_exercise, null: false
      t.references :content_tag, null: false

      t.timestamps null: false

      t.index [:content_exercise_id, :content_tag_id], unique: true,
              name: 'index_content_exercise_tags_on_c_e_id_and_c_t_id'
      t.index :content_tag_id
    end

    add_foreign_key :content_exercise_tags, :content_exercises,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :content_exercise_tags, :content_tags,
                    on_update: :cascade, on_delete: :cascade
  end
end
