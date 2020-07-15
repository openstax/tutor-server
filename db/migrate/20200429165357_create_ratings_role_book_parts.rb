class CreateRatingsRoleBookParts < ActiveRecord::Migration[5.2]
  def change
    create_table :ratings_role_book_parts do |t|
      t.references :entity_role,
                   null: false,
                   index: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.uuid :book_part_uuid, null: false, index: true
      t.boolean :is_page, null: false
      t.integer :num_responses, null: false
      t.jsonb :clue, null: false

      t.timestamps
    end

    add_index :ratings_role_book_parts, [ :entity_role_id, :book_part_uuid ],
              unique: true, name: 'index_role_book_parts_on_role_id_and_book_part_uuid'
  end
end
