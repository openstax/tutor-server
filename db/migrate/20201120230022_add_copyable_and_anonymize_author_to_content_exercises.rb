class AddCopyableAndAnonymizeAuthorToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises, :is_copyable, :boolean, null: false, default: true
    add_column :content_exercises, :anonymize_author, :boolean, null: false, default: false
  end
end
