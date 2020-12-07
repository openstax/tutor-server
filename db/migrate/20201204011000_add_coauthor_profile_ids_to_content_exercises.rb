class AddCoauthorProfileIdsToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises, :coauthor_profile_ids, :integer,
               array: true, default: []
    change_column_null :tasks_tasked_exercises, :url, true
  end
end
