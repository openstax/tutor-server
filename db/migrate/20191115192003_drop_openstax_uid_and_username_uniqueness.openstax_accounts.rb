# This migration comes from openstax_accounts (originally 14)
class DropOpenStaxUidAndUsernameUniqueness < ActiveRecord::Migration[5.2]
  def change
    remove_index :openstax_accounts_accounts, column: [ :openstax_uid ], unique: true
    remove_index :openstax_accounts_accounts, column: [ :username ], unique: true

    add_index :openstax_accounts_accounts, :openstax_uid
    add_index :openstax_accounts_accounts, :username
  end
end
