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
