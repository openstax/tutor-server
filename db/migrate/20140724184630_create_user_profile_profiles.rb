class CreateUserProfileProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :user_profile_profiles do |t|
      t.references :entity_user, null: false, index: { unique: true },
                                 foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :account, null: false, index: { unique: true }
      t.string :exchange_read_identifier, null: false
      t.string :exchange_write_identifier, null: false
      t.datetime :deleted_at

      t.timestamps null: false

      t.index :deleted_at
      t.index :exchange_read_identifier, unique: true
      t.index :exchange_write_identifier, unique: true
    end

    add_foreign_key :user_profile_profiles, :openstax_accounts_accounts,
                    column: :account_id, on_update: :cascade, on_delete: :cascade
  end
end
