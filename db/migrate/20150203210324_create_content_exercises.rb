class CreateContentExercises < ActiveRecord::Migration
  def change
    create_table :content_exercises do |t|
      t.resource
      t.string :title

      t.timestamps null: false

      t.resource_index
      t.index :title
    end
  end
end
