# This migration comes from openstax_accounts (originally 0)
class CreateOpenStaxAccountsAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :openstax_accounts_accounts do |t|
      t.integer :openstax_uid, :null => false
      t.string  :username, :null => false
      t.string  :access_token
      t.string  :first_name
      t.string  :last_name
      t.string  :full_name
      t.string  :title

      t.timestamps null: false

      t.index :openstax_uid, :unique => true
      t.index :username, :unique => true
      t.index :access_token, :unique => true
      t.index :first_name
      t.index :last_name
      t.index :full_name
    end
  end
end
