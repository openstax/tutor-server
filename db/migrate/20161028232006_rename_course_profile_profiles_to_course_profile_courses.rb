class RenameCourseProfileProfilesToCourseProfileCourses < ActiveRecord::Migration
  def change
    rename_table :course_profile_profiles, :course_profile_courses
  end
end
