class AddLmsEnabledFieldsToCourse < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :is_lms_enabled, :boolean, default: nil, null: true
    add_column :course_profile_courses, :is_lms_enabling_allowed, :boolean, default: false, null: false

    add_index :course_profile_courses, :is_lms_enabling_allowed
  end
end
