class CreateLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_platforms do |t|
      t.references :user_profile, index: true, foreign_key: {
        on_update: :cascade, on_delete: :restrict
      }
      t.string :issuer, null: false
      t.string :client_id, null: false
      t.string :deployment_id
      t.string :host, null: false
      t.string :jwks_endpoint, null: false
      t.string :authorization_endpoint, null: false
      t.string :token_endpoint, null: false
      t.uuid

      t.timestamps

      t.index [ :issuer ], where: '"deployment_id" IS NULL', unique: true
      t.index [ :issuer, :deployment_id ], unique: true
    end
  end
end
