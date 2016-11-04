class AddIsAvailableToCatalogOfferings < ActiveRecord::Migration
  def change
    add_column :catalog_offerings, :is_available, :boolean
    change_column_null :catalog_offerings, :is_available, false, true
  end
end
