class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :account, null: false
      t.string     :exchange_identifier, null: false
      t.datetime   :deleted_at

      t.timestamps null: false

      t.index :account_id, unique: true
      t.index :exchange_identifier, unique: true
      t.index :deleted_at
    end

    add_foreign_key :users, :openstax_accounts_accounts, column: :account_id,
                                                         on_update: :restrict,
                                                         on_delete: :restrict
  end
end
