class CreateTasksTaskedExercises < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_tasked_exercises do |t|
      t.references :content_exercise, null: false,
                                      index: true,
                                      foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.boolean :can_be_recovered, null: false, default: false
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :free_response
      t.string :answer_id

      t.timestamps null: false
    end

  end
end
