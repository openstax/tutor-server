# This migration comes from openstax_accounts (originally 4)
class CreateOpenStaxAccountsGroupNestings < ActiveRecord::Migration[4.2]
  def change
    create_table :openstax_accounts_group_nestings do |t|
      t.references :member_group, null: false
      t.references :container_group, null: false

      t.timestamps null: false

      t.index :member_group_id, unique: true
      t.index :container_group_id
    end
  end
end
