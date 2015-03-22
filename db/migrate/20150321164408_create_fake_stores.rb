return if !Rails.env.production?

class CreateFakeStores < ActiveRecord::Migration
  def change
    create_table :fake_stores do |t|
      t.text :store
      t.string :name
      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
