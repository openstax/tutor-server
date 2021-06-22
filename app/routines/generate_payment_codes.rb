class GeneratePaymentCodes
  lev_routine express_output: :codes, transaction: :read_committed

  protected

  def exec(prefix:, amount: 1, export_to_csv: false)
    codes = []

    amount.times do
      codes << PaymentCode.create!(prefix: prefix).code
    end

    outputs.codes = codes

    export(codes) if export_to_csv
  end

  def export(codes)
    path = File.join('tmp', 'exports', "payment-codes-#{SecureRandom.uuid}.csv")

    CSV.open(path, 'w') do |file|
      file << ['Code']
      codes.map {|c| file << [c] }
    end

    outputs.export_path = path
  end
end
