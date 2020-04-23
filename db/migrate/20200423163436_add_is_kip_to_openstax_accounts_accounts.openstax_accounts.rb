# This migration comes from openstax_accounts (originally 16)
class AddIsKipToOpenStaxAccountsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :openstax_accounts_accounts, :is_kip, :boolean
  end
end
