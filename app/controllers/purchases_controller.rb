class PurchasesController < ApplicationController

  def show
    student = CourseMembership::Models::Student.find_by!(uuid: params[:id])
    raise SecurityTransgression if student.role.role_user.profile != current_user.to_model
    redirect_to course_dashboard_path(student.course)
  end

end
