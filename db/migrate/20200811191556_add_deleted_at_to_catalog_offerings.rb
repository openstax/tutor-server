class AddDeletedAtToCatalogOfferings < ActiveRecord::Migration[5.2]
  def change
    add_column :catalog_offerings, :deleted_at, :datetime
  end
end
