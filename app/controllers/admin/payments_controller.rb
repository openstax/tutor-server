class Admin::PaymentsController < Admin::BaseController

  def index; end

  def extend_payment_due_at
    CourseMembership::Models::Student
      .joins(:course)
      .merge(CourseProfile::Models::Course.not_ended)
      .find_each do |student|

      # When due date nil, student model resets it before saving
      student.payment_due_at = nil
      student.save!
    end

    redirect_to admin_payments_path, notice: "Extended payment due dates"
  end

end
