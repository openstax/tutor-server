class MoveUsersToUserProfileUsers < ActiveRecord::Migration
  def change
    create_table :user_profile_profiles do |t|
      t.references :entity_user, null: false
      t.references :account, null: false
      t.string :exchange_identifier, null: false
      t.datetime :deleted_at

      t.timestamps null: false

      t.index :account_id, unique: true
      t.index :deleted_at
      t.index :exchange_identifier, unique: true
    end

    drop_table :users
    drop_table :user_profile_users
  end
end
