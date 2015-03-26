class RenameUserIdToProfileIdOnUserProfileAdministrators < ActiveRecord::Migration
  def change
    rename_column :user_profile_administrators, :user_id, :profile_id
  end
end
