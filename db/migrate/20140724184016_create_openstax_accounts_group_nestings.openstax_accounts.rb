# This migration comes from openstax_accounts (originally 4)
class CreateOpenStaxAccountsGroupNestings < ActiveRecord::Migration
  def change
    create_table :openstax_accounts_group_nestings do |t|
      t.references :member_group, null: false
      t.references :container_group, null: false

      t.timestamps null: false
    end

    add_index :openstax_accounts_group_nestings, :member_group_id, unique: true
    add_index :openstax_accounts_group_nestings, :container_group_id
  end
end
