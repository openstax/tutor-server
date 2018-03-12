class AddPeriodIdToStudents < ActiveRecord::Migration
  def change
    add_column :course_membership_students, :course_membership_period_id, :integer

    CourseMembership::Models::Student.preload(:latest_enrollment).find_each do |student|
      student.update_attribute(
        :course_membership_period_id, student.latest_enrollment.course_membership_period_id
      )
    end

    change_column_null :course_membership_students, :course_membership_period_id, false
  end
end
