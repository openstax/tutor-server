# This migration comes from openstax_accounts (originally 3)
class CreateOpenStaxAccountsGroupOwners < ActiveRecord::Migration[4.2]
  def change
    create_table :openstax_accounts_group_owners do |t|
      t.references :group, null: false
      t.references :user, null: false

      t.timestamps null: false

      t.index [:group_id, :user_id], unique: true
      t.index :user_id
    end
  end
end
