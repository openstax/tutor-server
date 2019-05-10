class RemoveUniqueFromEnrollmentChangesIndexOnEnrollmentId < ActiveRecord::Migration[4.2]
  def up
    remove_index :course_membership_enrollment_changes,
                 name: 'index_course_membership_enrollments_on_enrollment_id'
    add_index :course_membership_enrollment_changes, :course_membership_enrollment_id,
              name: 'index_course_membership_enrollments_on_enrollment_id'
  end

  def down
    remove_index :course_membership_enrollment_changes,
                 name: 'index_course_membership_enrollments_on_enrollment_id'
    add_index :course_membership_enrollment_changes, :course_membership_enrollment_id,
              name: 'index_course_membership_enrollments_on_enrollment_id', unique: true
  end
end
