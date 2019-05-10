class RenameCourseProfileProfilesToCourseProfileCourses < ActiveRecord::Migration[4.2]
  def change
    rename_table :course_profile_profiles, :course_profile_courses
  end
end
