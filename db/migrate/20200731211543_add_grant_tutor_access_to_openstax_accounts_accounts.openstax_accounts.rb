# This migration comes from openstax_accounts (originally 18)
class AddGrantTutorAccessToOpenStaxAccountsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :openstax_accounts_accounts, :grant_tutor_access, :boolean
  end
end
