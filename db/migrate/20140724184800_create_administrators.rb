class CreateAdministrators < ActiveRecord::Migration
  def change
    create_table :administrators do |t|
      t.references :profile, null: false

      t.timestamps null: false

      t.index :profile_id, unique: true
    end

    add_foreign_key :administrators, :users, on_update: :cascade,
                                             on_delete: :cascade
  end
end
