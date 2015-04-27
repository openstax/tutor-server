class CreateFakeStores < ActiveRecord::Migration
  def change
    create_table :fake_stores do |t|
      t.text :data
      t.string :name, null: false
      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
