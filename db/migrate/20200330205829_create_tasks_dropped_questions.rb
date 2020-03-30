class CreateTasksDroppedQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks_dropped_questions do |t|
      t.references :tasks_task_plan, null: false,
                                     index: false,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :question_id, null: false
      t.integer :drop_method, null: false

      t.timestamps
    end

    add_index :tasks_dropped_questions, [ :tasks_task_plan_id, :question_id ],
              unique: true, name: 'index_dropped_questions_on_task_plan_and_question_id'
  end
end
