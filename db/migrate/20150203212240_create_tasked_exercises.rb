class CreateTaskedExercises < ActiveRecord::Migration
  def change
    create_table :tasked_exercises do |t|
      t.timestamps null: false
    end
  end
end
