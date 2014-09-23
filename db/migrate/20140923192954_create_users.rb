class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :exchange_identifer
      t.integer :account_id
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :users, :account_id, unique: true
    add_index :users, :deleted_at
  end
end
