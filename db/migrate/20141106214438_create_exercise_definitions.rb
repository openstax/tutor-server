class CreateExerciseDefinitions < ActiveRecord::Migration
  def change
    create_table :exercise_definitions do |t|
      t.references :klass, null: false
      t.string :url
      t.text :content

      t.timestamps null: false
    end

    add_index :exercise_definitions, [:klass_id, :url], unique: true
  end
end
