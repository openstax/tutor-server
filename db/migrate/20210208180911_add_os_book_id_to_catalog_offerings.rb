class AddOsBookIdToCatalogOfferings < ActiveRecord::Migration[5.2]
  def change
    add_column :catalog_offerings, :os_book_id, :string
  end
end
