class AddDeletedAtToCourseMembershipPeriods < ActiveRecord::Migration
  def change
    add_column :course_membership_periods, :deleted_at, :datetime
  end
end
