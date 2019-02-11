class CreateNotesNotes < ActiveRecord::Migration
  def change
    create_table :notes_notes do |t|
      t.references :content_page,
                   null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role,
                   null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.text :anchor, null: false
      t.jsonb :contents, null: false
      t.timestamps null: false
    end
  end
end
