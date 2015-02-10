class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :parent_book
      t.integer :number, null: false
      t.string :title, null: false
      t.string :cnx_id, null: false
      t.string :version, null: false

      t.timestamps null: false
    end

    add_index :books, [:cnx_id, :version], unique: true
    add_index :books, [:parent_book_id, :number], unique: true

    add_foreign_key :books, :books, foreign_key: :parent_book_id,
                                    on_update: :cascade,
                                    on_delete: :cascade
  end
end
