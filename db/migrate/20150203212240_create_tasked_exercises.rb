class CreateTaskedExercises < ActiveRecord::Migration
  def change
    create_table :tasked_exercises do |t|
      t.references :recovery_tasked_exercise
      t.references :refresh_tasked, polymorphic: true
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :free_response
      t.string :answer_id

      t.timestamps null: false

      t.index :recovery_tasked_exercise_id, unique: true
      t.index [:refresh_tasked_id, :refresh_tasked_type], unique: true,
              name: 'index_tasked_exercises_on_r_t_id_and_r_t_type'
    end
  end
end
