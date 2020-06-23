# Note the V1s in these two namespaces are not the same -- later
# this class could be V7 and still inherit from V1 in the API gem.
#
class Api::V1::ApiController < OpenStax::Api::V1::ApiController
  # https://github.com/rails/rails/issues/34244#issuecomment-433365579
  # Remove in Rails 6 (fixed)
  def process_action(*args)
    super
  rescue ActionDispatch::Http::Parameters::ParseError => exception
    render status: 400, json: { errors: [ { message: exception.message } ] }
  end

  def error_if_student_and_needs_to_pay
    return if current_api_user.human_user.is_anonymous?

    course = if @course.present?
      @course
    elsif @student.present?
      @student.course
    elsif @task.present?
      # Assumes all tasks are assigned to one student
      @task.taskings.first.role.student.try!(:course)
    elsif @task_step.present?
      # Assumes all tasks are assigned to one student
      @task_step.task.taskings.first.role.student.try!(:course)
    else
      raise "Either @course, @student, @task, or @task_step must be set"
    end

    return if course.nil?

    student = UserIsCourseStudent.call(
      user: current_api_user.human_user, course: course
    ).outputs.student

    return if student.nil?

    render_api_errors(:payment_overdue) if payment_overdue?(course, student)
  end

  def render_job_id_json(job_id)
    render json: { job: api_job_path(job_id) }, status: :accepted
  end

  protected

  def payment_overdue?(course, student)
    Settings::Payments.payments_enabled && # payments are enabled
    !course.is_preview &&                  # not in a preview course
    course.does_cost &&                    # course does cost
    !student.is_paid &&                    # student has not paid yet
    !student.is_comped &&                  # student has not been comped
    student.payment_due_at.present? &&     # payment is eventually due
    Time.current >= student.payment_due_at # payment due date has passed
  end
end
