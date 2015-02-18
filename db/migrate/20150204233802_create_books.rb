class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :resource
      t.references :parent_book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false
    end

    add_index :books, [:parent_book_id, :number], unique: true
    add_index :books, :resource_id, unique: true

    add_foreign_key :books, :resources, on_update: :cascade,
                                        on_delete: :cascade
    add_foreign_key :books, :books, column: :parent_book_id,
                                    on_update: :cascade,
                                    on_delete: :cascade
  end
end
