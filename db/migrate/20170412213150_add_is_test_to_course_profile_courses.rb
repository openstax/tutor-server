class AddIsTestToCourseProfileCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :is_test, :boolean, null: false, default: false
  end
end
