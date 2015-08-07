class CreateContentPages < ActiveRecord::Migration
  def change
    create_table :content_pages do |t|
      t.resource
      t.references :content_chapter, null: false,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.integer :number, null: false
      t.string :title, null: false
      t.string :uuid
      t.string :version

      t.text :book_location, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:content_chapter_id, :number], unique: true
      t.index :title
    end
  end
end
