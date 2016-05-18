class ChangeTimezoneToCourseProfileTimeZoneId < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :course_profile_time_zone_id, :integer
    add_column :tasks_tasking_plans, :course_profile_time_zone_id, :integer
    add_column :tasks_tasks, :course_profile_time_zone_id, :integer

    rename_column :tasks_tasking_plans, :opens_at, :opens_at_ntz
    rename_column :tasks_tasking_plans, :due_at, :due_at_ntz

    rename_column :tasks_tasks, :opens_at, :opens_at_ntz
    rename_column :tasks_tasks, :due_at, :due_at_ntz
    rename_column :tasks_tasks, :feedback_at, :feedback_at_ntz

    reversible do |dir|
      dir.up do
        time_zones = {}

        CourseProfile::Models::Profile.find_each do |course_profile|
          time_zone = CourseProfile::Models::TimeZone.create!(name: course_profile.timezone)
          course_profile.update_attribute(time_zone: time_zone)
          time_zones[course_profile.entity_course_id] = time_zone
        end

        Tasks::Models::TaskingPlan.preload(task_plan: :owner).find_each do |tasking_plan|
          time_zone = time_zones[tasking_plan.task_plan.owner.id]
          tasking_plan.time_zone = time_zone
          tasking_plan.opens_at = tasking_plan.opens_at_ntz
          tasking_plan.due_at = tasking_plan.due_at_ntz
          tasking_plan.save!
        end

        Tasks::Models::Task.joins(taskings: :period)
                           .preload(taskings: :period).uniq.find_each do |task|
          time_zone = time_zones[task.taskings.first.period.entity_course_id]
          task.time_zone = time_zone
          task.opens_at = task.opens_at_ntz
          task.due_at = task.due_at_ntz
          task.feedback_at = task.feedback_at_ntz
          task.save!
        end
      end

      dir.down do
        Tasks::Models::Task.joins(taskings: :period).uniq.find_each do |task|
          task.opens_at_ntz = task.opens_at.utc
          task.due_at_ntz = task.due_at.utc
          task.feedback_at_ntz = task.feedback_at.utc
          task.save!
        end

        Tasks::Models::TaskingPlan.find_each do |tasking_plan|
          tasking_plan.opens_at_ntz = tasking_plan.opens_at
          tasking_plan.due_at_ntz = tasking_plan.due_at
          tasking_plan.save!
        end

        CourseProfile::Models::Profile.update_all(
          'timezone = course_profile_time_zones.name
           FROM course_profile_time_zones
           WHERE course_profile_time_zones.id = course_profile_time_zone_id'
        )
      end
    end

    change_column_null :course_profile_profiles, :course_profile_time_zone_id, false
    add_index :course_profile_profiles, :course_profile_time_zone_id, unique: true
    add_foreign_key :course_profile_profiles, :course_profile_time_zones,
                    on_update: :cascade, on_delete: :nullify

    change_column_null :tasks_tasking_plans, :course_profile_time_zone_id, false
    add_index :tasks_tasking_plans, :course_profile_time_zone_id
    add_foreign_key :tasks_tasking_plans, :course_profile_time_zones,
                    on_update: :cascade, on_delete: :nullify

    add_index :tasks_tasks, :course_profile_time_zone_id
    add_foreign_key :tasks_tasks, :course_profile_time_zones,
                    on_update: :cascade, on_delete: :nullify

    change_column_null :tasks_tasks, :opens_at_ntz, true

    remove_column :course_profile_profiles, :timezone, :string,
                  null: false, default: 'Central Time (US & Canada)'
  end
end
