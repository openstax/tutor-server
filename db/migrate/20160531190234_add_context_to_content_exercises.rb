class AddContextToContentExercises < ActiveRecord::Migration
  def change
    add_column :content_exercises, :context, :text
  end
end
