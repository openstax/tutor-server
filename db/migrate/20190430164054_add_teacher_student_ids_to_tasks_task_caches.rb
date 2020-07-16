class AddTeacherStudentIdsToTasksTaskCaches < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_task_caches, :teacher_student_ids, :integer, array: true

    change_column_null :tasks_task_caches, :teacher_student_ids, false

    add_index :tasks_task_caches, :teacher_student_ids, using: :gin
  end
end
