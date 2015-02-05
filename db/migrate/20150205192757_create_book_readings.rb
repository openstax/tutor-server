class CreateBookReadings < ActiveRecord::Migration
  def change
    create_table :book_readings do |t|
      t.references :book, null: false
      t.references :reading, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :book_readings, [:reading_id, :book_id], unique: true
    add_index :book_readings, [:book_id, :number], unique: true
  end
end
