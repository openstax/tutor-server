class ImproveDeletedAtIndices < ActiveRecord::Migration[4.2]
  def change
    add_index :course_membership_enrollment_changes, :deleted_at

    add_index :course_membership_enrollments, :deleted_at

    remove_index :course_membership_periods,
                 column: [:entity_course_id, :name],
                 unique: true,
                 where: "(deleted_at IS NULL)"
    add_index :course_membership_periods, [:name, :entity_course_id],
              unique: true, where: "(deleted_at IS NULL)"
    add_index :course_membership_periods, :entity_course_id
    add_index :course_membership_periods, :deleted_at

    remove_index :course_membership_students,
                 column: [:entity_course_id, :deleted_at],
                 name: 'course_membership_students_course_inactive'
    remove_index :course_membership_students,
                 column: [:student_identifier, :entity_course_id],
                 name: 'index_course_membership_students_on_s_identifier_and_e_c_id',
                 unique: true
    add_index :course_membership_students, [:entity_course_id, :student_identifier],
              name: 'index_course_membership_students_on_e_c_id_and_s_identifier', unique: true
    add_index :course_membership_students, :deleted_at
  end
end
