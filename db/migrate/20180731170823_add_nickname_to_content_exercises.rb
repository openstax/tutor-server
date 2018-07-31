class AddNicknameToContentExercises < ActiveRecord::Migration
  def change
    add_column :content_exercises, :nickname, :string
  end
end
