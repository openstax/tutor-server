class CreateLegacyUserUsers < ActiveRecord::Migration
  def change
    create_table :legacy_user_users do |t|
      t.integer :user_id,        null: false
      t.integer :entity_user_id, null: false
      t.timestamps null: false

      t.index :user_id, unique: true
    end

    add_foreign_key :legacy_user_users, :users
    add_foreign_key :legacy_user_users, :entity_users
  end
end
