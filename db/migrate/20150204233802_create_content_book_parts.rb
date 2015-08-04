class CreateContentBookParts < ActiveRecord::Migration
  def change
    create_table :content_book_parts do |t|
      t.resource allow_nil: true
      t.references :parent_book_part
      t.references :content_book, null: false,
                                  index: true,
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :chapter_section
      t.string :uuid
      t.string :version

      t.timestamps null: false

      t.resource_index
      t.index [:parent_book_part_id, :number], unique: true
    end

    add_foreign_key :content_book_parts, :content_book_parts,
                    column: :parent_book_part_id, on_update: :cascade, on_delete: :cascade
  end
end
