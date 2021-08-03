class CreateTasksPreviousAttempts < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks_previous_attempts do |t|
      t.references :tasks_tasked_exercise, null: false, index: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.integer :number, null: false
      t.datetime :attempted_at, null: false
      t.text :free_response
      t.string :answer_id

      t.timestamps

      t.index [ :tasks_tasked_exercise_id, :number ], unique: true,
              name: 'index_tasks_previous_attempts_on_tasks_te_id_and_number'
    end
  end
end
