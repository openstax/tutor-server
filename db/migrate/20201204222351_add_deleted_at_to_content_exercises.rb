class AddDeletedAtToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises, :deleted_at, :datetime
  end
end
