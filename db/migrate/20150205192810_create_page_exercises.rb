class CreatePageExercises < ActiveRecord::Migration
  def change
    create_table :page_exercises do |t|
      t.references :page, null: false
      t.references :exercise, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :page_exercises, [:exercise_id, :page_id], unique: true
    add_index :page_exercises, [:page_id, :number], unique: true

    add_foreign_key :page_exercises, :pages, on_update: :cascade,
                                             on_delete: :cascade
    add_foreign_key :page_exercises, :exercises, on_update: :cascade,
                                                 on_delete: :cascade
  end
end
