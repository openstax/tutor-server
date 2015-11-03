class AddStudentIdentifierToCourseMembershipStudents < ActiveRecord::Migration
  def change
    add_column :course_membership_students, :student_identifier, :string
    add_index :course_membership_students, :student_identifier
  end
end
