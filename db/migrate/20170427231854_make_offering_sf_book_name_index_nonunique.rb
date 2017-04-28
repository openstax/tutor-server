class MakeOfferingSfBookNameIndexNonunique < ActiveRecord::Migration
  def change
    remove_index :catalog_offerings, :salesforce_book_name
    add_index :catalog_offerings, :salesforce_book_name
  end
end
