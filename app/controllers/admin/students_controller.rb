class Admin::StudentsController < Admin::BaseController
  include Manager::StudentActions

  def update
    student = CourseMembership::Models::Student.find(params[:id])

    local_params = params[:course_membership_models_student].permit(:is_comped, :payment_due_at)

    if local_params[:payment_due_at].present?
      local_params[:payment_due_at] =
        DateTimeUtilities.parse_in_zone(string: local_params[:payment_due_at],
                                        zone: student.course.time_zone.name).midnight + 1.day - 1.second
    end

    respond_to do |format|
      if student.update_attributes(local_params)
        format.json { respond_with_bip(student) }
      else
        format.json { respond_with_bip(student) }
      end
    end
  end

  def destroy
    student = CourseMembership::Models::Student.find(params[:id])
    CourseMembership::InactivateStudent[student: student]
    redirect_to edit_admin_course_path(student.course) + '#roster'
  end

  def refund
    student = CourseMembership::Models::Student.find(params[:id])
    RefundPayment[uuid: student.uuid]
    redirect_to edit_admin_course_path(student.course, anchor: "roster")
  end

  def restore
    student = CourseMembership::Models::Student.find(params[:id])
    CourseMembership::ActivateStudent[student: student]
    redirect_to edit_admin_course_path(student.course) + '#roster'
  end

end
