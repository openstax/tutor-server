# This migration comes from openstax_accounts (originally 12)
class AddIsTestToAccountsAccounts < ActiveRecord::Migration
  def change
    add_column :openstax_accounts_accounts, :is_test, :boolean
  end
end
