class CreateTasksTaskPageCaches < ActiveRecord::Migration
  def change
    create_table :tasks_task_page_caches do |t|
      t.references :tasks_task,                null: false, index: true, foreign_key: {
                                                 on_update: :cascade, on_delete: :cascade
                                               }
      t.references :content_page,              null: false, index: true, foreign_key: {
                                                 on_update: :cascade, on_delete: :cascade
                                               }
      t.references :course_membership_student, null: false, foreign_key: {
                                                 on_update: :cascade, on_delete: :cascade
                                               }
      t.integer :num_assigned_exercises,       null: false
      t.integer :num_completed_exercises,      null: false
      t.integer :num_correct_exercises,        null: false

      t.timestamps                             null: false
    end

    add_index :tasks_task_page_caches,
              [ :course_membership_student_id, :content_page_id, :tasks_task_id ],
              name: 'index_task_page_caches_on_student_and_page_and_task',
              unique: true
  end
end
