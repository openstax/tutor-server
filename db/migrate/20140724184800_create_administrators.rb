class CreateAdministrators < ActiveRecord::Migration
  def change
    create_table :administrators do |t|
      t.references :profile, null: false

      t.timestamps null: false

      t.index :profile_id, unique: true
    end

  end
end
