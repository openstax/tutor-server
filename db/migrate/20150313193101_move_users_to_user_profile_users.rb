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

    [:educators, :students].each do |table|
        remove_foreign_key table, :users

        add_foreign_key table, :user_profile_profiles, column: :user_id,
                        on_update: :cascade, on_delete: :cascade
    end

    add_foreign_key :administrators, :user_profile_profiles, column: :profile_id,
                    on_update: :cascade, on_delete: :cascade

    # can't remove the table until all the fk's that point to it are removed
    drop_table :users
    drop_table :user_profile_users
  end
end
