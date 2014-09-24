# This migration comes from openstax_accounts (originally 1)
class CreateOpenStaxAccountsGroups < ActiveRecord::Migration
  def change
    create_table :openstax_accounts_groups do |t|
      t.integer :openstax_uid, :null => false
      t.boolean :is_public, null: false, default: false
      t.string :name
      t.text :cached_subtree_group_ids
      t.text :cached_supertree_group_ids

      t.timestamps
    end

    add_index :openstax_accounts_groups, :openstax_uid, :unique => true
    add_index :openstax_accounts_groups, :is_public
  end
end
