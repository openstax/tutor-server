class AddDeletedAtToRoleRoleUsers < ActiveRecord::Migration
  def change
    add_column :role_role_users, :deleted_at, :datetime

    add_index :role_role_users, :deleted_at
  end
end
