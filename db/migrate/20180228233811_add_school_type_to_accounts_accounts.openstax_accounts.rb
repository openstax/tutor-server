# This migration comes from openstax_accounts (originally 13)
class AddSchoolTypeToAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    add_column :openstax_accounts_accounts, :school_type, :integer, null: false, default: 0
    add_index :openstax_accounts_accounts, :school_type
  end
end
