class CreateUserProfileAdministrators < ActiveRecord::Migration[4.2]
  def change
    create_table :user_profile_administrators do |t|
      t.references :profile, null: false, index: { unique: true }

      t.timestamps null: false
    end

    add_foreign_key :user_profile_administrators, :user_profile_profiles,
                    column: :profile_id, on_update: :cascade, on_delete: :cascade
  end
end
