class MoveAdministratorsToUserProfileAdministrators < ActiveRecord::Migration
  def change
    rename_table :administrators, :user_profile_administrators
  end
end
