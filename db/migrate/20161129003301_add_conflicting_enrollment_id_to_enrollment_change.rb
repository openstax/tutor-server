class AddConflictingEnrollmentIdToEnrollmentChange < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_enrollment_changes,
               :course_membership_conflicting_enrollment_id,
               :integer

    add_index :course_membership_enrollment_changes, :course_membership_conflicting_enrollment_id,
              name: 'index_c_m_enrollment_changes_on_c_m_conflicting_enrollment_id'
  end
end
