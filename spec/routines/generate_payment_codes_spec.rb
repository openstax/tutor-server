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

    it 'exports a csv with codes' do
      path = described_class.call(prefix: 'abc', export_to_csv: true).outputs.export_path
      expect(File.exist?(path)).to be(true)
      expect(path.ends_with? '.csv').to be(true)
      rows = CSV.read(path)
      expect(rows[0][0]).to eq('Code')
      expect(rows[1][0]).to match(CODE_REGEX)
    end
  end
end
