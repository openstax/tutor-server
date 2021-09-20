class CreateLtiUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_users do |t|
      t.references :user_profile, index: true, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.references :lti_platform, null:false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.string :uid, null: false
      t.string :last_message_type, null: false
      t.string :last_context_id, null: false
      t.boolean :last_is_instructor, null: false
      t.boolean :last_is_student, null: false
      t.text :last_target_link_uri, null: false

      t.timestamps

      t.index [ :lti_platform_id, :uid ], unique: true
    end
  end
end
