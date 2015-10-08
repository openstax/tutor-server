class AddEnrollmentCodeToCourseMembershipPeriods < ActiveRecord::Migration
  def change
    add_column :course_membership_periods, :enrollment_code, :string, null: false
    add_index :course_membership_periods, :enrollment_code, unique: true
  end
end
