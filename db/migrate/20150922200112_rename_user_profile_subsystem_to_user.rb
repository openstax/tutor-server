class RenameUserProfileSubsystemToUser < ActiveRecord::Migration[4.2]
  def up
    # Drop foreign key constraints
    remove_foreign_key :user_profile_profiles, :entity_users
    remove_foreign_key :user_profile_administrators, :user_profile_profiles
    remove_foreign_key :user_profile_content_analysts, :user_profile_profiles
    remove_foreign_key :role_role_users, :entity_users

    # Rename tables
    rename_table :user_profile_profiles, :user_profiles
    rename_table :user_profile_administrators, :user_administrators
    rename_table :user_profile_content_analysts, :user_content_analysts

    # Rename columns
    rename_column :user_administrators, :user_profile_profile_id, :user_profile_id
    rename_column :user_content_analysts, :user_profile_profile_id, :user_profile_id

    # Change administrator and content analyst records to point to the entity_user_id field instead of the id
    execute 'UPDATE user_administrators SET user_profile_id = (SELECT entity_user_id FROM user_profiles WHERE user_profile_id = user_profiles.id);'
    execute 'UPDATE user_content_analysts SET user_profile_id = (SELECT entity_user_id FROM user_profiles WHERE user_profile_id = user_profiles.id);'

    # Rename the role_role_users entity_user_id column to user_profile_id
    rename_column :role_role_users, :entity_user_id, :user_profile_id

    # Change profile id to match the entity_user_id
    execute 'UPDATE user_profiles SET id = entity_user_id;'

    # Drop the entity_user_id column
    remove_column :user_profiles, :entity_user_id

    # Drop the entity_users table
    drop_table :entity_users

    # Readd foreign key constraints
    add_foreign_key :user_administrators, :user_profiles, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_content_analysts, :user_profiles, on_update: :cascade,
                                                            on_delete: :cascade
    add_foreign_key :role_role_users, :user_profiles, on_update: :cascade, on_delete: :cascade
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
