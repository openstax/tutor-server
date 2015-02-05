class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :resource, null: false

      t.timestamps null: false
    end

    add_index :books, :resource_id, unique: true
  end
end
