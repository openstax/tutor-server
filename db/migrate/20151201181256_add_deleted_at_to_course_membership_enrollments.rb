class AddDeletedAtToCourseMembershipEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_enrollments, :deleted_at, :datetime
  end
end
