class AddAuthorToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises,
               :user_profile_id,
               :integer,
               null: false,
               default: User::Models::OpenStaxProfile::ID
    add_index :content_exercises, :user_profile_id
  end
end
