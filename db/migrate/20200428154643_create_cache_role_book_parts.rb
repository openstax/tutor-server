class CreateCacheRoleBookParts < ActiveRecord::Migration[5.2]
  def change
    create_table :cache_role_book_parts do |t|
      t.references :entity_role,
                   null: false,
                   index: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.uuid :book_part_uuid, null: false, index: true
      t.boolean :is_page, null: false
      t.jsonb :clue, null: false
      t.boolean :is_cached_for_period, default: false, null: false

      t.timestamps
    end

    add_index :cache_role_book_parts, [ :entity_role_id, :book_part_uuid ], unique: true,
              unique: true, name: 'index_role_book_parts_on_role_id_and_book_part_uuid'
  end
end
