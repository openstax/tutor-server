class AddTitleAndNumberToCatalogOfferings < ActiveRecord::Migration
  def change
    add_column :catalog_offerings, :title, :string
    add_column :catalog_offerings, :number, :integer

    reversible do |dir|
      dir.up do
        Catalog::Models::Offering.unscoped.find_each.with_index do |offering, index|
          offering.title = offering.salesforce_book_name || ''
          offering.number = index + 1
          offering.save validate: false
        end
      end
    end

    change_column_null :catalog_offerings, :title, false
    change_column_null :catalog_offerings, :number, false

    add_index :catalog_offerings, :title
    add_index :catalog_offerings, :number, unique: true
  end
end
