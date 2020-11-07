class AddAuthorToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises,
               :author_id,
               :integer,
               null: false,
               default: User::Models::OpenStaxProfile::ID
  end
end
