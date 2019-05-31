class AddNicknameToContentExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :content_exercises, :nickname, :string
  end
end
