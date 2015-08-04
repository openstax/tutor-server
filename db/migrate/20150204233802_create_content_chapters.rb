class CreateContentChapters < ActiveRecord::Migration
  def change
    create_table :content_chapters do |t|
      t.references :content_book, null: false,
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :book_location
      t.string :uuid
      t.string :version
      t.text :toc_cache
      t.text :page_data_cache

      t.timestamps null: false

      t.index [:content_book_id, :number], unique: true
      t.index :title
    end
  end
end
