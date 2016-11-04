# This migration comes from openstax_accounts (originally 7)
class ChangeAccountsOpenStaxUidToBeNullable < ActiveRecord::Migration
  def change
    change_column_null :openstax_accounts_accounts, :openstax_uid, true
  end
end
