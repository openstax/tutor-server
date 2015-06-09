class CreateContentPages < ActiveRecord::Migration
  def change
    create_table :content_pages do |t|
      t.resource
      t.references :content_book_part
      t.integer :number, null: false
      t.string :title, null: false
      t.text :chapter_section
      t.string :uuid
      t.string :version

      t.timestamps null: false

      t.resource_index
      t.index [:content_book_part_id, :number], unique: true
    end

    add_foreign_key :content_pages, :content_book_parts, on_update: :cascade, on_delete: :cascade
  end
end
