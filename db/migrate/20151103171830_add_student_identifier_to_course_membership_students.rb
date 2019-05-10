class AddStudentIdentifierToCourseMembershipStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_students, :student_identifier, :string
    add_index :course_membership_students, [:student_identifier, :entity_course_id],
              name: 'index_course_membership_students_on_s_identifier_and_e_c_id', unique: true
  end
end
