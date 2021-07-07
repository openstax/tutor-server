require 'rails_helper'

RSpec.describe RedeemPaymentCode, type: :routine do
  let(:student) { FactoryBot.create(:course_membership_student) }
  let(:payment_code) { FactoryBot.create(:payment_code) }
  let(:used_payment_code) { FactoryBot.create(:payment_code, redeemed_at: 1.day.ago) }

  it 'redeems a code' do
    outputs = described_class.call(student: student, payment_code: payment_code).outputs
    expect(outputs.payment_code.redeemed?).to be true
    expect(student.is_paid).to be true
    expect(outputs.errors).to be nil
    expect(student.payment_code.id).to eq(payment_code.id)
  end

  it 'does not redeem a redeemed code' do
    outputs = described_class.call(student: student, payment_code: used_payment_code).outputs
    expect(outputs.payment_code.redeemed?).to be true
    expect(outputs.payment_code.redeemed_at).to eq(used_payment_code.redeemed_at)
    expect(student.is_paid).to be false
    expect(outputs.errors[:code]).to eq(:already_redeemed)
  end
end
