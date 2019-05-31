class AddEnrollmentCodeToCourseMembershipPeriods < ActiveRecord::Migration[4.2]
  def change
    add_column :course_membership_periods, :enrollment_code, :string
    add_index :course_membership_periods, :enrollment_code, unique: true

    reversible do |direction|
      direction.up do
        CourseMembership::Models::Period.unscoped
                                        .where(enrollment_code: nil)
                                        .find_each(&:save!) # generates tokens
        change_column :course_membership_periods, :enrollment_code, :string, null: false
      end
    end
  end
end
