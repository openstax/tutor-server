class GeneratePaymentCodes
  lev_routine express_output: :codes, transaction: :read_committed

  protected

  def exec(prefix:, amount: 1, generate_csv: false)
    codes = []
    errors = []
    total_retries = 0

    unless amount.is_a?(Integer) && amount > 0 && amount < 1000
      outputs.errors = ['Amount must be a whole number between 1 and 999']
      return
    end

    amount.times do
      retries = 0
      pc = PaymentCode.new(prefix: prefix)

      begin
        pc.save!
        codes << pc.code
      rescue ActiveRecord::RecordInvalid
        if retries < 3
          retries += 1
          total_retries += 1
          retry
        end

        errors << pc.errors
      end
    end

    outputs.retries = total_retries
    outputs.codes = codes
    outputs.errors = errors.map(&:full_messages).uniq
    outputs.csv = generate_csv(codes) if generate_csv && errors.empty?
  end

  def generate_csv(codes)
    CSV.generate(headers: true) do |csv|
      csv << ['Code']
      codes.map {|c| csv << [c] }
    end
  end
end
