class AddIsRefundPendingToCourseMembershipStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_students, :is_refund_pending, :boolean, default: false, null: false
  end
end
