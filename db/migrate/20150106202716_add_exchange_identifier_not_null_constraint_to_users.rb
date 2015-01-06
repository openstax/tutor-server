class AddExchangeIdentifierNotNullConstraintToUsers < ActiveRecord::Migration
  def change
    change_column :users, :exchange_identifier, :string, :null => false
  end
end
