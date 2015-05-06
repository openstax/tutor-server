class CreateUserProfileProfiles < ActiveRecord::Migration
  def change
    create_table :user_profile_profiles do |t|
      t.references :entity_user, null: false
      t.references :account, null: false
      t.string :exchange_read_identifier, null: false
      t.string :exchange_write_identifier, null: false
      t.datetime :deleted_at

      t.timestamps null: false

      t.index :account_id, unique: true
      t.index :deleted_at
      t.index :exchange_read_identifier, unique: true
      t.index :exchange_write_identifier, unique: true
    end
  end
end
