class ReorganizeLmsTables < ActiveRecord::Migration

  # Make sure this class always exist when this migration is run, in case it
  # goes away one day.
  class Lms::Models::Nonce < Tutor::SubSystems::BaseModel; end

  def up
    remove_index :lms_nonces, name: :nonce_consumer_value
    remove_reference :lms_nonces, :lms_tool_consumer

    drop_table :lms_tool_consumers

    create_table :lms_apps do |t|
      t.references :owner, polymorphic: true, index: true, null: false
      t.string :key, null: false, index: true
      t.string :secret, null: false
      t.timestamps
    end

    Lms::Models::Nonce.destroy_all

    add_reference :lms_nonces, :lms_app, null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
    add_index :lms_nonces, [:lms_app_id, :value], unique: true, name: 'lms_nonce_app_value'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
