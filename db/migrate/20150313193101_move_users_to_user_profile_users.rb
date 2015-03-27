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

    ::User.find_each do |user|
      attrs = { account_id: user.account_id,
                exchange_identifier: user.exchange_identifier,
                deleted_at: user.deleted_at,
                created_at: user.created_at,
                updated_at: user.updated_at }

      if profile = UserProfile::User.find_by(user_id: user.id)
        attrs.merge!(entity_user_id: profile.entity_user_id)
        profile.destroy
      end

      Domain::CreateUserProfile.call(attrs)
    end

    UserProfile::Models::User.find_each do |up_user|
      Domain::CreateUserProfile.call(entity_user_id: up_user.entity_user_id,
                                     created_at: up_user.created_at,
                                     updated_at: up_user.updated_at)
    end

    drop_table :users
    drop_table :user_profile_users
  end
end
