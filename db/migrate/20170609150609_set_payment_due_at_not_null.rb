class SetPaymentDueAtNotNull < ActiveRecord::Migration
  def change
    CourseMembership::Models::Student.where(payment_due_at: nil)
                                     .preload(course: :time_zone)
                                     .find_each do |student|
      payment_due_at = student.created_at.in_time_zone(student.course.time_zone.to_tz).midnight +
                       1.day - 1.second + Settings::Payments.student_grace_period_days.days

      student.update_attribute :payment_due_at, payment_due_at
    end

    change_column_null :course_membership_students, :payment_due_at, false
  end
end
