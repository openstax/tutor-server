class AddSolutionsArePublicToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises, :solutions_are_public, :boolean
    change_column_default :content_exercises, :solutions_are_public, false
  end
end
