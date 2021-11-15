# This migration comes from openstax_accounts (originally 19)
class AddIsAdministratorToOpenStaxAccountsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :openstax_accounts_accounts, :is_administrator, :boolean
  end
end