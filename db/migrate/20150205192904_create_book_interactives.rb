class CreateBookInteractives < ActiveRecord::Migration
  def change
    create_table :book_interactives do |t|
      t.references :book, null: false
      t.references :interactive, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :book_interactives, [:interactive_id, :book_id], unique: true
    add_index :book_interactives, [:book_id, :number], unique: true
  end
end
