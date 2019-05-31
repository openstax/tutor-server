class CreateContentExerciseTags < ActiveRecord::Migration[4.2]
  def change
    create_table :content_exercise_tags do |t|
      t.references :content_exercise, null: false,
                                      foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_tag, null: false, index: true,
                                 foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false

      t.index [:content_exercise_id, :content_tag_id], unique: true,
              name: 'index_content_exercise_tags_on_c_e_id_and_c_t_id'
    end
  end
end
