class CreateLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_platforms do |t|
      t.uuid :guid, default: 'gen_random_uuid()', null: false, index: { unique: true }
      t.references :user_profile, null: false, index: true, foreign_key: {
        on_update: :cascade, on_delete: :restrict
      }
      t.string :issuer, null: false
      t.string :client_id, null: false
      t.string :host, null: false
      t.string :jwks_endpoint, null: false
      t.string :authorization_endpoint, null: false
      t.string :token_endpoint, null: false

      t.timestamps
    end
  end
end
