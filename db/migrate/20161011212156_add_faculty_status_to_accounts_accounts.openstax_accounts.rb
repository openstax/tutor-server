# This migration comes from openstax_accounts (originally 5)
class AddFacultyStatusToAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    add_column :openstax_accounts_accounts, :faculty_status, :integer, default: 0, null: false
    add_index :openstax_accounts_accounts, :faculty_status
  end
end
