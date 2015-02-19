class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.resource
      t.references :book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:book_id, :number], unique: true
    end

    add_foreign_key :pages, :books, on_update: :cascade, on_delete: :cascade
  end
end
