class CreateContentPages < ActiveRecord::Migration
  def change
    create_table :content_pages do |t|
      t.resource
      t.references :content_book_part, null: false,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :chapter_section
      t.string :uuid
      t.string :version

      t.timestamps null: false

      t.resource_index(url_not_unique: true)
      t.index [:content_book_part_id, :url], unique: true
      t.index [:content_book_part_id, :number], unique: true
    end
  end
end
