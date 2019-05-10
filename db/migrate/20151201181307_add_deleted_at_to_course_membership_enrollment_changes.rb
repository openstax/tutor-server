class AddDeletedAtToCourseMembershipEnrollmentChanges < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_enrollment_changes, :deleted_at, :datetime
  end
end
