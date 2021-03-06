require 'rails_helper'

RSpec.describe PaymentCode, type: :model do
  subject(:pc) { FactoryBot.create :payment_code }

  context 'with a new record' do
    it 'generates codes' do
      new_pc = described_class.new(prefix: 'NEW')
      new_pc.save
      expect(new_pc.code).to match(/^NEW\-[a-zA-Z0-9]{10}$/)
    end

    it 'requires a prefix' do
      new_pc = described_class.new(prefix: '')
      expect { new_pc.save }.to raise_error(ActiveRecord::RecordInvalid)
      expect(new_pc.errors.types).to include(:prefix)
    end

    it 'regenerates a code when a collision occurs' do
      new_pc = described_class.new
      allow(new_pc).to receive(:generate_code).and_return(pc.code, pc.code, 'new-code')
      new_pc.save
      expect(new_pc).to have_received(:generate_code).at_least(:thrice)
      expect(new_pc.code).not_to eq(pc.code)
    end
  end

  context 'with a persisted record' do
    it 'cannot change a code once persisted' do
      expect { pc.send(:code=, 'test') }.to throw_symbol(:cannot_change_persisted_code)

      expect {
        pc.redeemed_at = 1.day.ago
        pc.save
      }.not_to change{ pc.code }.from(pc.code)

      expect {
        pc.write_attribute(:code, 'changed')
        pc.save
      }.to throw_symbol(:cannot_change_persisted_code)

      expect { pc.send(:set_code) }.to throw_symbol(:cannot_change_persisted_code)
    end
  end
end
