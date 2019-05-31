class AddEstimatedStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :estimated_student_count, :integer
  end
end
