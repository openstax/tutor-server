class AddPathToBooks < ActiveRecord::Migration
  def change
    add_column :content_books, :path, :string
  end
end
