class AddCourseIsAccessSwitchable < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :is_access_switchable, :boolean, default: true, null: false
  end
end
