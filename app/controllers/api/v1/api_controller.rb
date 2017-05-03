# Note the V1s in these two namespaces are not the same -- later
# this class could be V7 and still inherit from V1 in the API gem.
#
class Api::V1::ApiController < OpenStax::Api::V1::ApiController

  def error_if_student_and_needs_to_pay
    return true if current_api_user.human_user.is_anonymous?

    if @student.present?
      student = @student
      course = @student.course
    elsif @course.present?
      course = @course
      student = UserIsCourseStudent.call(
        user: current_api_user.human_user, course: @course
      ).outputs.student
    elsif @task.present?
      student = @task.taskings.first.role.student
      course = student.try!(:course)
    elsif @task_step.present?
      # Assumes all tasks are assigned to one student
      student = @task_step.task.taskings.first.role.student
      course = student.try!(:course)
    else
      raise "Either @student, @course, @task, or @task_step must be set"
    end

    payment_overdue?(course, student) ? render_api_errors(:payment_overdue) : true
  end

  protected

  def payment_overdue?(course, student)
    return false if student.nil?                        # only students need to pay
    return false if course.is_preview                   # preview courses should never cost
    return false if !course.does_cost
    return false if student.payment_due_at.nil?
    return false if Time.now < student.payment_due_at   # not overdue yet
    return false if student.is_paid
    return false if student.is_comped
    return true
  end

end
