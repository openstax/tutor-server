class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.references :resource, null: false
      t.references :book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false
    end

    add_index :pages, [:book_id, :number], unique: true
    add_index :pages, :resource_id, unique: true

    add_foreign_key :pages, :resources, on_update: :cascade,
                                        on_delete: :cascade
    add_foreign_key :pages, :books, on_update: :cascade, on_delete: :cascade
  end
end
