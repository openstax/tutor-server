class CreateExercises < ActiveRecord::Migration
  def change
    create_table :exercises do |t|
      t.references :resource, null: false

      t.timestamps null: false
    end

    add_index :exercises, :resource_id, unique: true
  end
end
