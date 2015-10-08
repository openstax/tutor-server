class AddEnrollmentCodeToCourseMembershipPeriods < ActiveRecord::Migration
  def change
    add_column :course_membership_periods, :enrollment_code, :string
    add_index :course_membership_periods, :enrollment_code, unique: true

    reversible do |dir|
      dir.up do
        CourseMembership::Models::Period.where(enrollment_code: nil).find_each do |period|
          period.send(:generate_enrollment_code)
          period.save!
        end

        change_column :course_membership_periods, :enrollment_code, :string, null: false
      end
    end
  end
end
