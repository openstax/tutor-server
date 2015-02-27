class CreateContentPages < ActiveRecord::Migration
  def change
    create_table :content_pages do |t|
      t.resource
      t.references :content_book_part
      t.references :entity_book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:content_book_part_id, :number], unique: true
      t.index :entity_book_id
    end

    add_foreign_key :content_pages, :content_books, on_update: :cascade, 
                                                    on_delete: :cascade

    add_foreign_key :content_pages, :entity_books, on_update: :cascade, 
                                                   on_delete: :cascade                                                    
  end
end
