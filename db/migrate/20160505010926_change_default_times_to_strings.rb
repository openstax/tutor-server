class ChangeDefaultTimesToStrings < ActiveRecord::Migration
  def change
    remove_column :course_membership_periods, :default_open_time
    remove_column :course_membership_periods, :default_due_time
    remove_column :course_profile_profiles, :default_open_time
    remove_column :course_profile_profiles, :default_due_time

    add_column :course_membership_periods, :default_open_time, :string
    add_column :course_membership_periods, :default_due_time, :string
    add_column :course_profile_profiles, :default_open_time, :string
    add_column :course_profile_profiles, :default_due_time, :string
  end
end
