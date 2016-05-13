class ChangeTimezoneToCourseProfileTimeZoneId < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :course_profile_time_zone_id, :integer
    add_column :tasks_tasking_plans, :course_profile_time_zone_id, :integer
    add_column :tasks_tasks, :course_profile_time_zone_id, :integer

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
          tasking_plan.opens_at = tasking_plan.read_attribute :opens_at
          tasking_plan.due_at = tasking_plan.read_attribute :due_at
          tasking_plan.save!
        end

        Tasks::Models::Task.joins(taskings: :period)
                           .preload(taskings: :period).uniq.find_each do |task|
          time_zone = time_zones[task.taskings.first.period.entity_course_id]
          task.time_zone = time_zone
          task.opens_at = task.read_attribute :opens_at
          task.due_at = task.read_attribute :due_at
          task.feedback_at = task.read_attribute :feedback_at
          task.save!
        end
      end

      dir.down do
        Tasks::Models::Task.joins(taskings: :period).uniq.find_each do |task|
          task.write_attribute :opens_at, task.opens_at
          task.write_attribute :due_at, task.due_at
          task.write_attribute :feedback_at, task.feedback_at
          task.save!
        end

        Tasks::Models::TaskingPlan.find_each do |tasking_plan|
          tasking_plan.write_attribute :opens_at, tasking_plan.opens_at
          tasking_plan.write_attribute :due_at, tasking_plan.due_at
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

    change_column_null :tasks_tasks, :opens_at, true

    remove_column :course_profile_profiles, :timezone, :string,
                  null: false, default: 'Central Time (US & Canada)'
  end
end
