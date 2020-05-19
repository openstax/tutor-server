class DenormalizeTimeZones < ActiveRecord::Migration[5.2]
  def up
    add_column :course_profile_courses, :timezone, :string

    CourseProfile::Models::Course.update_all(
      <<~UPDATE_SQL
        "timezone" = CASE "time_zones"."name"
          WHEN 'Eastern Time (US & Canada)' THEN 'US/Eastern'
          WHEN 'Pacific Time (US & Canada)' THEN 'US/Pacific'
          WHEN 'Mountain Time (US & Canada)' THEN 'US/Mountain'
          WHEN 'Arizona' THEN 'US/Arizona'
          WHEN 'Hawaii' THEN 'US/Hawaii'
          WHEN 'Alaska' THEN 'US/Alaska'
          WHEN 'Indiana (East)' THEN 'US/East-Indiana'
          WHEN 'Atlantic Time (Canada)' THEN 'Canada/Atlantic'
          ELSE 'US/Central'
        END
        FROM "time_zones"
        WHERE "time_zones"."id" = "course_profile_courses"."time_zone_id"
      UPDATE_SQL
    )

    change_column_null :course_profile_courses, :timezone, false

    add_reference :tasks_tasks, :course_profile_course,
                  foreign_key: { on_update: :cascade, on_delete: :cascade }

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

    remove_index :tasks_task_plans, column: [ :owner_id, :owner_type ]

    rename_column :tasks_task_plans, :owner_id, :course_profile_course_id
    remove_column :tasks_task_plans, :owner_type

    add_index :tasks_task_plans, :course_profile_course_id

    remove_column :course_profile_courses, :time_zone_id
    remove_column :tasks_tasking_plans, :time_zone_id
    remove_column :tasks_tasks, :time_zone_id

    drop_table :time_zones
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
