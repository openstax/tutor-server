# This migration comes from openstax_accounts (originally 8)
class ChangeAccountsUsernameToBeNullable < ActiveRecord::Migration
  def change
    change_column_null :openstax_accounts_accounts, :username, true
  end
end
