class GeneratePaymentCodeReport
  lev_routine express_output: :export_path

  def exec
    path = File.join('tmp', 'exports', "payment-code-report.csv")

    CSV.open(path, 'w') do |file|
      file << [
        'Code',
        'Redeemed At',
        'Course UUID',
        'Student Tutor ID',
        'Student Identifier'
      ]
      PaymentCode.in_batches.each_record do |pc|
        file << [
          pc.code,
          pc.redeemed_at,
          pc&.student&.course&.id,
          pc&.student&.id,
          pc&.student&.student_identifier
        ]
      end
    end

    outputs.export_path = path
  end
end
