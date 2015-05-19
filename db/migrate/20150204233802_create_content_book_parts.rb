class CreateContentBookParts < ActiveRecord::Migration
  def change
    create_table :content_book_parts do |t|
      t.resource allow_nil: true
      t.references :parent_book_part
      t.references :entity_book
      t.integer :number, null: false
      t.string :title, null: false
      t.text :chapter_section

      t.timestamps null: false

      t.resource_index
      t.index [:parent_book_part_id, :number], unique: true
      t.index :entity_book_id
    end

    add_foreign_key :content_book_parts, :content_book_parts,
                    column: :parent_book_part_id, on_update: :cascade, on_delete: :cascade

    add_foreign_key :content_book_parts, :entity_books, on_update: :cascade, on_delete: :cascade
  end
end
