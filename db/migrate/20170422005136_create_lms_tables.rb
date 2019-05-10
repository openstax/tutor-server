class CreateLmsTables < ActiveRecord::Migration[4.2]
  def change
    create_table :lms_tool_consumers do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :secret, null: false
      t.string :owner_id, null: false
      t.text :notes
      t.timestamps
    end

    create_table :lms_nonces do |t|
      t.string :value, limit: 128, null: false
      t.references :lms_tool_consumer,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.datetime :created_at
      t.index [:lms_tool_consumer_id, :value], unique: true, name: 'nonce_consumer_value'
    end
  end
end
