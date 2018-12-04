class AddBakedBookLocationColumns < ActiveRecord::Migration
  def change
    add_column :content_chapters, :baked_book_location, :text, null: false, default: '[]'
    add_column :content_pages, :baked_book_location, :text, null: false, default: '[]'
    add_column :tasks_tasked_readings, :baked_book_location, :text, null: false, default: '[]'
  end
end
