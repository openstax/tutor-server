class CreateTasksTaskedExercises < ActiveRecord::Migration
  def change
    create_table :tasks_tasked_exercises do |t|
      t.references :exercise
      t.boolean :has_recovery, null: false, default: false
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :free_response
      t.string :answer_id

      t.timestamps null: false

      t.index :exercise_id
    end
  end
end
