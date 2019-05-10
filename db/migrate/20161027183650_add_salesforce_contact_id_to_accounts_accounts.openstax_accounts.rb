# This migration comes from openstax_accounts (originally 6)
class AddSalesforceContactIdToAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    add_column :openstax_accounts_accounts, :salesforce_contact_id, :string
    add_index :openstax_accounts_accounts, :salesforce_contact_id
  end
end
