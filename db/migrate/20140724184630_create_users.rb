class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references  :account, null: false
      t.string      :exchange_identifier, null: false
      t.datetime    :deleted_at

      t.timestamps null: false
    end

    add_index :users, :account_id, unique: true
    add_index :users, :exchange_identifier, unique: true
    add_index :users, :deleted_at
  end
end
