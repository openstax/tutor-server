class CleanupDeletedAtColumns < ActiveRecord::Migration[4.2]
  def up
    remove_index :cc_page_stats,
                 column: %w{course_period_id coach_task_content_page_id group_type},
                 unique: true,
                 name: 'cc_page_stats_uniq'
    remove_index :cc_page_stats, column: :course_period_id
    drop_view :cc_page_stats, materialized: true

    remove_column :user_profiles, :deleted_at, :datetime

    remove_column :course_membership_enrollments, :deleted_at, :datetime
    remove_column :course_membership_enrollment_changes, :deleted_at, :datetime

    remove_column :tasks_tasking_plans, :deleted_at, :datetime

    remove_column :tasks_tasks, :deleted_at, :datetime

    remove_column :tasks_taskings, :deleted_at, :datetime

    remove_column :tasks_concept_coach_tasks, :deleted_at, :datetime

    remove_column :tasks_task_steps, :deleted_at, :datetime
    remove_column :tasks_tasked_readings, :deleted_at, :datetime
    remove_column :tasks_tasked_exercises, :deleted_at, :datetime
    remove_column :tasks_tasked_interactives, :deleted_at, :datetime
    remove_column :tasks_tasked_videos, :deleted_at, :datetime
    remove_column :tasks_tasked_external_urls, :deleted_at, :datetime
    remove_column :tasks_tasked_placeholders, :deleted_at, :datetime

    rename_column :course_membership_periods, :deleted_at, :archived_at
    rename_column :course_membership_students, :deleted_at, :dropped_at
    rename_column :tasks_task_plans, :deleted_at, :withdrawn_at

    add_column :content_ecosystems, :deleted_at, :datetime
    add_column :course_profile_courses, :deleted_at, :datetime
    add_column :course_membership_teachers, :deleted_at, :datetime

    remove_foreign_key :tasks_concept_coach_tasks, :tasks_tasks
    add_foreign_key :tasks_concept_coach_tasks, :tasks_tasks,
                    on_update: :cascade, on_delete: :cascade

    remove_foreign_key :tasks_taskings, :tasks_tasks
    add_foreign_key :tasks_taskings, :tasks_tasks,
                    on_update: :cascade, on_delete: :cascade

    remove_foreign_key :course_profile_courses, :time_zones
    add_foreign_key :course_profile_courses, :time_zones, on_update: :cascade

    remove_foreign_key :tasks_tasking_plans, :time_zones
    add_foreign_key :tasks_tasking_plans, :time_zones, on_update: :cascade

    create_view :cc_page_stats, materialized: true, version: 2
    add_index :cc_page_stats, %w{course_period_id coach_task_content_page_id group_type},
              unique: true, name: 'cc_page_stats_uniq'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
