class RenameUserProfileAdministratorsProfileIdToUserProfileProfileId < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_profile_administrators, :profile_id, :user_profile_profile_id
  end
end
