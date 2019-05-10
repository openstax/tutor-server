class AddShortIdToBookAndPage < ActiveRecord::Migration[4.2]
  def change
    add_column :content_books, :short_id, :string
    add_column :content_pages, :short_id, :string
  end
end
