class AllowDuplicateStudentIds < ActiveRecord::Migration[4.2]
  def change
    remove_index :course_membership_students,
                 column: [:course_profile_course_id, :student_identifier],
                 name: "index_course_membership_students_on_e_c_id_and_s_identifier",
                 where: 'deleted_at IS NULL',
                 unique: true

    add_index :course_membership_students,
              [:course_profile_course_id, :student_identifier],
              name: "index_course_membership_students_on_c_p_c_id_and_s_identifier"
  end
end
