class CreateUserProfileAdministrators < ActiveRecord::Migration
  def change
    create_table :user_profile_administrators do |t|
      t.references :profile, null: false

      t.timestamps null: false

      t.index :profile_id, unique: true
    end

    add_foreign_key :user_profile_administrators, :user_profile_profiles,
                    column: :profile_id, on_update: :cascade, on_delete: :cascade
  end
end
