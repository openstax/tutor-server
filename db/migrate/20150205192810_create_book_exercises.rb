class CreateBookExercises < ActiveRecord::Migration
  def change
    create_table :book_exercises do |t|
      t.references :book, null: false
      t.references :exercise, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :book_exercises, [:exercise_id, :book_id], unique: true
    add_index :book_exercises, [:book_id, :number], unique: true
  end
end
