class CreateAdministrators < ActiveRecord::Migration
  def change
    create_table :administrators do |t|
      t.references :user, null: false

      t.timestamps
    end

    add_index :administrators, :user_id, unique: true
  end
end
