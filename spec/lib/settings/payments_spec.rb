require 'rails_helper'

RSpec.describe Settings::Payments, type: :lib do
  it 'can store student_grace_period_days' do
    expect(described_class.student_grace_period_days).to eq 14

    begin
      described_class.student_grace_period_days = 10
      expect(described_class.student_grace_period_days).to eq 10
    ensure
      described_class.student_grace_period_days = 14
    end
  end

  it 'can store payments_enabled' do
    expect(described_class.payments_enabled).to eq false

    begin
      described_class.payments_enabled = true
      expect(described_class.payments_enabled).to eq true
    ensure
      described_class.payments_enabled = false
    end
  end
end
