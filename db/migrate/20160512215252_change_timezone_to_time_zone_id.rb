class ChangeTimezoneToTimeZoneId < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :time_zone_id, :integer
    add_column :tasks_tasking_plans, :time_zone_id, :integer
    add_column :tasks_tasks, :time_zone_id, :integer

    rename_column :tasks_tasking_plans, :opens_at, :opens_at_ntz
    rename_column :tasks_tasking_plans, :due_at, :due_at_ntz

    rename_column :tasks_tasks, :opens_at, :opens_at_ntz
    rename_column :tasks_tasks, :due_at, :due_at_ntz
    rename_column :tasks_tasks, :feedback_at, :feedback_at_ntz

    change_column_null :course_profile_profiles, :time_zone_id, false
    add_index :course_profile_profiles, :time_zone_id, unique: true
    add_foreign_key :course_profile_profiles, :time_zones, on_update: :cascade, on_delete: :nullify

    change_column_null :tasks_tasking_plans, :time_zone_id, false
    add_index :tasks_tasking_plans, :time_zone_id
    add_foreign_key :tasks_tasking_plans, :time_zones, on_update: :cascade, on_delete: :nullify

    add_index :tasks_tasks, :time_zone_id
    add_foreign_key :tasks_tasks, :time_zones, on_update: :cascade, on_delete: :nullify

    change_column_null :tasks_tasks, :opens_at_ntz, true

    remove_column :course_profile_profiles, :timezone, :string,
                  null: false, default: 'Central Time (US & Canada)'
  end
end
