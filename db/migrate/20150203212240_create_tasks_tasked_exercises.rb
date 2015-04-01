class CreateTasksTaskedExercises < ActiveRecord::Migration
  def change
    create_table :tasks_tasked_exercises do |t|
      t.references :recovery_tasked_exercise
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :free_response
      t.string :answer_id

      t.timestamps null: false

      t.index :recovery_tasked_exercise_id, unique: true
    end

    add_foreign_key :tasked_exercises, :tasked_exercises,
                    column: :recovery_tasked_exercise_id,
                    on_update: :cascade, on_delete: :nullify
  end
end
