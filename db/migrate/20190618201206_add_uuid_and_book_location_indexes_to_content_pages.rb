class AddUuidAndBookLocationIndexesToContentPages < ActiveRecord::Migration[5.2]
  def change
    add_index :content_pages, :uuid
    add_index :content_pages, :book_location
  end
end
