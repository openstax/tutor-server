class AddDeletedAtToCourseMembershipEnrollments < ActiveRecord::Migration
  def change
    add_column :course_membership_enrollments, :deleted_at, :datetime
  end
end
