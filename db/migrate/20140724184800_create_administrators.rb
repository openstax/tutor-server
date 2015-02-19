class CreateAdministrators < ActiveRecord::Migration
  def change
    create_table :administrators do |t|
      t.references :user, null: false

      t.timestamps null: false

      t.index :user_id, unique: true
    end

    add_foreign_key :administrators, :users, on_update: :cascade,
                                             on_delete: :cascade
  end
end
