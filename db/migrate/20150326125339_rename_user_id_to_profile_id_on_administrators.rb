class RenameUserIdToProfileIdOnAdministrators < ActiveRecord::Migration
  def change
    rename_column :administrators, :user_id, :profile_id
  end
end
