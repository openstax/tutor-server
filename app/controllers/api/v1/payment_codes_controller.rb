class Api::V1::PaymentCodesController < Api::V1::ApiController

  before_action :verify_existance

  resource_description do
    api_versions "v1"
    short_description 'Interface for payment codes'
    description <<-EOS
    EOS
  end

  api :PUT, '/payment_codes/:code/redeem', 'Redeems a payment code purchased from a bookstore'
  description <<-EOS
    Redeems a payment code purchased from a bookstore.

    Responses:
    * 200 code was successfully redeemed
    * 404 if the code does not exist
    * 422 with code 'already_redeemed' if the code is found but already redeemed
  EOS
  def redeem
    outputs = RedeemPaymentCode.call(student: student, payment_code: payment_code).outputs
    if outputs.errors
      render_api_errors(outputs.errors)
    else
      head :ok
    end
  end

  protected

  def payment_code
    @payment_code ||= PaymentCode.find_by(code: params[:code])
  end

  def course
    @course ||= CourseProfile::Models::Course.find params[:course_id]
  end

  def student
    @student ||= UserIsCourseStudent.call(user: current_human_user, course: course).outputs.student
  end

  def verify_existance
    head :not_found unless course && student && payment_code
  end
end
