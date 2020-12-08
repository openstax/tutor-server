class AddDerivedFromToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_reference :content_exercises, :derived_from, foreign_key: { to_table: :content_exercises }
  end
end
