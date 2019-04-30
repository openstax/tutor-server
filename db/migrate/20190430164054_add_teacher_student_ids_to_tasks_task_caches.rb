class AddTeacherStudentIdsToTasksTaskCaches < ActiveRecord::Migration
  def change
    add_column :tasks_task_caches, :teacher_student_ids, :integer, array: true

    reversible do |dir|
      dir.up do
        Tasks::Models::TaskCache.reset_column_information

        Tasks::Models::TaskCache.select(
          [ :id, '"course_membership_teacher_students"."id" AS "teacher_student_id"' ]
        ).joins(task: { taskings: { role: :teacher_student } }).find_each do |task_cache|
          task_cache.update_attribute :teacher_student_ids, [ task_cache.teacher_student_id ]
        end

        Tasks::Models::TaskCache.where(teacher_student_ids: nil).update_all(teacher_student_ids: [])
      end
    end

    change_column_null :tasks_task_caches, :teacher_student_ids, false

    add_index :tasks_task_caches, :teacher_student_ids, using: :gin
  end
end
