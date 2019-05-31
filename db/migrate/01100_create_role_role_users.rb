class CreateRoleRoleUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :role_role_users do |t|
      t.references :entity_user, null: false, foreign_key: { on_update: :cascade,
                                                             on_delete: :cascade }
      t.references :entity_role, null: false, foreign_key: { on_update: :cascade,
                                                             on_delete: :cascade }
      t.timestamps null: false

      t.index [:entity_user_id, :entity_role_id], unique: true,
                                                  name: 'role_role_users_user_role_uniq'
    end
  end
end
