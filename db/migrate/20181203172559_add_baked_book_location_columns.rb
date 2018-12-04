class AddBakedBookLocationColumns < ActiveRecord::Migration
  def change
    add_column :content_chapters, :baked_book_location, :text
    add_column :content_pages, :baked_book_location, :text
    add_column :tasks_tasked_readings, :baked_book_location, :text
  end
end
