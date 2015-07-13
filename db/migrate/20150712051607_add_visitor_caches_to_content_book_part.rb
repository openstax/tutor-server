class AddVisitorCachesToContentBookPart < ActiveRecord::Migration
  def change
    add_column :content_book_parts, :toc_cache, :text
    add_column :content_book_parts, :page_data_cache, :text
  end
end
