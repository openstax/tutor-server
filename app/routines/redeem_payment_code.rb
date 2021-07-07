class RedeemPaymentCode
  lev_routine express_output: :payment_code, transaction: :read_committed

  def exec(student:, payment_code:)
    outputs.payment_code = payment_code

    if payment_code.redeemed?
      outputs.errors = {
        code: :already_redeemed,
        message: 'Code is already in use'
      }
    elsif student.is_paid
      outputs.errors = {
        code: :student_is_paid,
        message: 'Student has already paid'
      }
    else
      paid_at = Time.current
      payment_code.redeemed_at = paid_at
      payment_code.student = student
      payment_code.save!
      student.is_paid = true
      student.first_paid_at = paid_at
      student.save!
    end
  end
end
