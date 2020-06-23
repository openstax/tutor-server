class PopulateExistingTaskCourseIds < ActiveRecord::Migration[5.2]
  def up
    # Some really old tasks had their taskings deleted at some point
    # These tasks are essentially lost so we might as well delete them now
    Tasks::Models::Task.where(
      <<~WHERE_SQL
        NOT EXISTS (
          SELECT *
          FROM "tasks_taskings"
          WHERE "tasks_taskings"."tasks_task_id" = "tasks_tasks"."id"
        )
      WHERE_SQL
    ).delete_all

    Tasks::Models::Task.preload(taskings: { role: [ :student, :teacher_student ] })
                       .find_in_batches do |tasks|
      tasks.each do |task|
        task.course_profile_course_id =
          task.taskings.first.role.course_member.course_profile_course_id
      end

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: :id, columns: [ :course_profile_course_id ]
      }
    end

    change_column_null :tasks_tasks, :course_profile_course_id, false
  end

  def down
  end
end
