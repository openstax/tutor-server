class CreateContentNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :content_notes do |t|
      t.references :content_page,
                   null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role,
                   null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.text :anchor, null: false
      t.text :annotation
      t.jsonb :contents, null: false
      t.timestamps null: false
    end
  end
end
