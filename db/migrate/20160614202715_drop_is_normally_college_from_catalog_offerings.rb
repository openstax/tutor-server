class DropIsNormallyCollegeFromCatalogOfferings < ActiveRecord::Migration[4.2]
  def change
    remove_column :catalog_offerings, :is_normally_college
  end
end
