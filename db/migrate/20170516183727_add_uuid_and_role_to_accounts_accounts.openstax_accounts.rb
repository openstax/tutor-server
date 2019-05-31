# This migration comes from openstax_accounts (originally 9)
class AddUuidAndRoleToAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    add_column :openstax_accounts_accounts, :uuid, :string
    add_index :openstax_accounts_accounts, :uuid, unique: true

    add_column :openstax_accounts_accounts, :role, :integer, default: 0, null: false
    add_index :openstax_accounts_accounts, :role
  end
end
