class AddDeletedAtToCourseMembershipPeriods < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_periods, :deleted_at, :datetime
  end
end
