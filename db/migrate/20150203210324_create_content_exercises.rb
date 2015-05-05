class CreateContentExercises < ActiveRecord::Migration
  def change
    create_table :content_exercises do |t|
      t.resource
      t.integer :number, null: false
      t.integer :version, null: false
      t.string :title

      t.timestamps null: false

      t.resource_index
      t.index [:number, :version], unique: true
      t.index :title
    end
  end
end
