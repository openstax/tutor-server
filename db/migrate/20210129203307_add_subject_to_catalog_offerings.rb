class AddSubjectToCatalogOfferings < ActiveRecord::Migration[5.2]
  def change
    add_column :catalog_offerings, :subject, :string
  end
end
