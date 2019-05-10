class MakeOfferingSfBookNameIndexNonunique < ActiveRecord::Migration[4.2]
  def change
    remove_index :catalog_offerings, :salesforce_book_name
    add_index :catalog_offerings, :salesforce_book_name
  end
end
