require 'rails_helper'

RSpec.describe PaymentCode, type: :model do
  subject(:pc) { FactoryBot.create :payment_code }

  it 'generates codes' do
    new_pc = described_class.new(prefix: 'NEW')
    new_pc.save
    expect(new_pc.code).to match(/^NEW\-[a-zA-Z0-9]{10}$/)
  end

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
  end
end
