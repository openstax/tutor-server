class CreateTasksTaskedExercises < ActiveRecord::Migration
  def change
    create_table :tasks_tasked_exercises do |t|
      t.references :content_exercise
      t.boolean :can_be_recovered, null: false, default: false
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :free_response
      t.string :answer_id

      t.timestamps null: false

      t.index :content_exercise_id
    end

  end
end
