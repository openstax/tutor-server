class AddContextFieldsAndFlagsToContentExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :content_exercises, :preview, :text
    add_column :content_exercises, :context, :text
    add_column :content_exercises, :has_interactive, :boolean, null: false, default: false
    add_column :content_exercises, :has_video, :boolean, null: false, default: false
  end
end
