# This migration comes from openstax_accounts (originally 3)
class CreateOpenStaxAccountsGroupOwners < ActiveRecord::Migration
  def change
    create_table :openstax_accounts_group_owners do |t|
      t.references :group, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :openstax_accounts_group_owners, [:group_id, :user_id], unique: true
    add_index :openstax_accounts_group_owners, :user_id
  end
end
