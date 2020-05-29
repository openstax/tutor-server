# This migration comes from openstax_accounts (originally 17)
class AddSchoolLocationToOpenStaxAccountsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :openstax_accounts_accounts, :school_location, :integer, default: 0, null: false
  end
end
