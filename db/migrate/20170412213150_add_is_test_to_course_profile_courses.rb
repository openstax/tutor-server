class AddIsTestToCourseProfileCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :is_test, :boolean, null: false, default: false
  end
end
