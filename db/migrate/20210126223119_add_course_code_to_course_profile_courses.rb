class AddCourseCodeToCourseProfileCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :course_profile_courses, :code, :string
  end
end
