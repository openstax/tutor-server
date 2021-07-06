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

  def generate_payment_codes
    params.require(:prefix)
    params.require(:amount)

    generator = GeneratePaymentCodes.call(
      prefix: params[:prefix],
      amount: params[:amount].to_i,
      generate_csv: true
    ).outputs

    if generator.errors.any?
      flash[:error] = generator.errors
      redirect_to admin_payments_path
    else
      send_data generator.csv,
                filename: "payment-codes-#{SecureRandom.uuid}.csv"
    end
  end

  def download_payment_code_report
    send_data GeneratePaymentCodeReport.call.outputs.csv,
              filename: "payment-code-report-#{SecureRandom.uuid}.csv"
  end
end
