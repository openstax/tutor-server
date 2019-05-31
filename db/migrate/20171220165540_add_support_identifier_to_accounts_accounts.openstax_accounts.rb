# This migration comes from openstax_accounts (originally 11)
class AddSupportIdentifierToAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    enable_extension :citext

    add_column :openstax_accounts_accounts, :support_identifier, :citext
    add_index :openstax_accounts_accounts, :support_identifier, unique: true
  end
end
