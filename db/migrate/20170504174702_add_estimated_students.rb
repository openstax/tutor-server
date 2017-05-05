class AddEstimatedStudents < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :estimated_student_count, :integer
  end
end
