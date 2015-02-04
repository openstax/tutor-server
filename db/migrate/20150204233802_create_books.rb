class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :url, null: false
      t.string :title, null: false
      t.string :edition, null: false

      t.timestamps null: false
    end

    add_index :books, :url, unique: true
    add_index :books, [:title, :edition], unique: true
  end
end
