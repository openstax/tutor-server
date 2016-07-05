class DropIsNormallyCollegeFromCatalogOfferings < ActiveRecord::Migration
  def change
    remove_column :catalog_offerings, :is_normally_college
  end
end
