class AddDefaultTimesToCoursesAndPeriods < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_periods, :default_open_time, :time
    add_column :course_membership_periods, :default_due_time, :time
    add_column :course_profile_profiles, :default_open_time, :time
    add_column :course_profile_profiles, :default_due_time, :time
  end
end
