class CreateRatingsExerciseGroupBookParts < ActiveRecord::Migration[5.2]
  def change
    create_table :ratings_exercise_group_book_parts do |t|
      t.uuid :exercise_group_uuid, null: false
      t.uuid :book_part_uuid, null: false, index: true
      t.boolean :is_page, null: false
      t.integer :tasked_exercise_ids, array: true, null: false
      t.float :glicko_mu, null: false
      t.float :glicko_phi, null: false
      t.float :glicko_sigma, null: false

      t.timestamps
    end

    add_index :ratings_exercise_group_book_parts, [ :exercise_group_uuid, :book_part_uuid ],
              unique: true, name: 'index_ex_group_book_parts_on_ex_group_uuid_and_book_part_uuid'
  end
end
