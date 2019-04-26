class DropRoleRoleUsers < ActiveRecord::Migration
  def change
    add_column :entity_roles, :user_profile_id, :integer

    reversible do |dir|
      dir.up do
        Entity::Role.reset_column_information

        Entity::Role.find_each do |role|
          user_profile_id = ActiveRecord::Base.connection.execute(
            <<-SQL.strip_heredoc
              SELECT "role_role_users"."user_profile_id"
              FROM "role_role_users"
              WHERE "role_role_users"."entity_role_id" = #{role.id}
            SQL
          ).to_a.first

          role.update_attribute(:user_profile_id, user_profile_id) unless user_profile_id.nil?
        end

        Entity::Role.where(user_profile_id: nil).delete_all
      end

      dir.down do
        Entity::Role.find_each do |role|
          ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
            INSERT INTO "role_role_users"
            ("entity_role_id", "user_profile_id", "created_at", "updated_at")
            VALUES (#{role.id}, #{role.user_profile_id}, #{role.created_at}, #{role.updated_at})
          SQL
        end
      end
    end

    change_column_null :entity_roles, :user_profile_id, false

    add_index :entity_roles, :user_profile_id

    add_foreign_key :entity_roles, :user_profiles, on_update: :cascade, on_delete: :cascade

    remove_foreign_key :role_role_users, column: :user_profile_id,
                                         on_update: :cascade,
                                         on_delete: :cascade
    remove_foreign_key :role_role_users, column: :entity_role_id,
                                         on_update: :cascade,
                                         on_delete: :cascade

    remove_index :role_role_users, column: [:user_profile_id, :entity_role_id],
                                   name: "role_role_users_user_role_uniq",
                                   unique: true

    drop_table :role_role_users, force: :cascade do |t|
      t.integer  :user_profile_id, null: false
      t.integer  :entity_role_id,  null: false
      t.datetime :created_at,      null: false
      t.datetime :updated_at,      null: false
    end
  end
end
