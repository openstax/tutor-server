class RenameLegacyUserUsersToUserProfileUser < ActiveRecord::Migration
  def change
    rename_table :legacy_user_users, :user_profile_users
  end
end
