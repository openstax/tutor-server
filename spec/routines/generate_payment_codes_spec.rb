require 'rails_helper'

RSpec.describe GeneratePaymentCodes, type: :routine do
  CODE_REGEX = /^ABC\-[a-zA-Z0-9]{10}$/

  context 'with a prefix' do
    it 'generates some codes' do
      codes = described_class.call(prefix: 'abc').outputs.codes
      expect(codes.count).to eq(1)
      codes.each do |c|
        expect(c).to match(CODE_REGEX)
      end
    end

    it 'generates a csv with codes' do
      csv = CSV.parse(described_class.call(prefix: 'abc', generate_csv: true).outputs.csv)
      expect(csv[0][0]).to eq('Code')
      expect(csv[1][0]).to match(CODE_REGEX)
    end
  end

  context 'with invalid params' do
    it 'surfaces validation errors' do
      gc = described_class.call(prefix: '', amount: 1).outputs
      expect(gc.errors).to eq([["Prefix can't be blank"]])

      gc = described_class.call(prefix: 'Valid', amount: 'A').outputs
      expect(gc.errors).to eq(['Amount must be a whole number between 1 and 999'])
    end
  end

  context 'when something goes wrong' do
    it 'retries' do
      allow_any_instance_of(PaymentCode).to receive(:generate_code).and_return('1', '1', '2')
      gc = described_class.call(prefix: '', amount: 2).outputs
      expect(gc.retries).to eq(2)
      expect(gc.errors).to be_empty
    end
  end
end
