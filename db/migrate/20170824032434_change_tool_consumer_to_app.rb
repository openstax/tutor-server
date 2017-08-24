class ChangeToolConsumerToApp < ActiveRecord::Migration
  def change
    rename_table :lms_tool_consumers, :lms_apps

    remove_column :lms_apps, :owner_id, :integer
    add_reference :lms_apps, :owner, polymorphic: true, index: true, null: false

    remove_index :lms_nonces, name: :nonce_consumer_value
    remove_reference :lms_nonces, :lms_tool_consumer

    add_reference :lms_nonces, :lms_app, null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
    add_index :lms_nonces, [:lms_app_id, :value], unique: true, name: 'lms_nonce_app_value'
  end
end
