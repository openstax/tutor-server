class ChangeDefaultTimesToStrings < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_membership_periods, :default_open_time, :time
    remove_column :course_membership_periods, :default_due_time, :time
    remove_column :course_profile_profiles, :default_open_time, :time
    remove_column :course_profile_profiles, :default_due_time, :time

    add_column :course_membership_periods, :default_open_time, :string
    add_column :course_membership_periods, :default_due_time, :string
    add_column :course_profile_profiles, :default_open_time, :string
    add_column :course_profile_profiles, :default_due_time, :string
  end
end
