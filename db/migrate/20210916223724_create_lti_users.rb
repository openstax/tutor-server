class CreateLtiUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_users do |t|
      t.references :user_profile, null: false, index: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.references :lti_platform, null:false, index: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.string :uid, null: false

      t.timestamps

      t.index [ :user_profile_id, :lti_platform_id ], unique: true
      t.index [ :lti_platform_id, :uid ], unique: true
    end
  end
end
