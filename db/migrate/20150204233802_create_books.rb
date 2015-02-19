class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.resource allow_nil: true
      t.references :parent_book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:parent_book_id, :number], unique: true
    end

    add_foreign_key :books, :books, column: :parent_book_id,
                                    on_update: :cascade,
                                    on_delete: :cascade
  end
end
