class AddCourseIsAccessSwitchable < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :is_access_switchable, :boolean, default: true, null: false
  end
end
