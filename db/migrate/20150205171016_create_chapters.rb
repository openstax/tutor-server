class CreateChapters < ActiveRecord::Migration
  def change
    create_table :chapters do |t|
      t.references :book, null: false
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false
    end

    add_index :chapters, [:book_id, :number], unique: true
    add_index :chapters, [:title, :book_id], unique: true

    add_foreign_key :chapters, :books, on_update: :cascade, on_delete: :cascade
  end
end
