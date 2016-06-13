class CreateContentMaps < ActiveRecord::Migration
  def change
    create_table :content_maps do |t|
      t.references :content_from_ecosystem, null: false
      t.references :content_to_ecosystem, null: false, index: true
      t.jsonb :exercise_id_to_page_map, null: false
      t.jsonb :page_id_to_page_map, null: false
      t.jsonb :page_id_to_pool_type_exercises_map, null: false
      t.boolean :is_valid, null: false
      t.string :validity_error_messages, array: true, null: false

      t.timestamps null: false

      t.index [:content_from_ecosystem_id, :content_to_ecosystem_id],
              unique: true, name: 'index_content_maps_on_from_ecosystem_id_and_to_ecosystem_id'
    end

    add_foreign_key :content_maps, :content_ecosystems,
                    column: :content_from_ecosystem_id, on_update: :cascade, on_delete: :cascade
    add_foreign_key :content_maps, :content_ecosystems,
                    column: :content_to_ecosystem_id, on_update: :cascade, on_delete: :cascade
  end
end
