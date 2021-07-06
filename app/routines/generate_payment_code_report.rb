class GeneratePaymentCodeReport
  lev_routine express_output: :csv

  def exec(since: 1.year.ago)
    outputs.csv = CSV.generate(headers: true) do |csv|
      csv << [
        'Code',
        'Redeemed At',
        'Course UUID',
        'Student Tutor ID',
        'Student Identifier'
      ]

      range = since.midnight..DateTime::Infinity.new

      PaymentCode.where(created_at: range).in_batches.each_record do |pc|
        csv << [
          pc.code,
          pc.redeemed_at,
          pc&.student&.course&.id,
          pc&.student&.id,
          pc&.student&.student_identifier
        ]
      end
    end
  end
end
