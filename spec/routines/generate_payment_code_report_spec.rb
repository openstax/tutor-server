require 'rails_helper'

RSpec.describe GeneratePaymentCodeReport, type: :routine do
  context 'when generating a report on code use' do
    it 'generates an inline csv with codes and other data' do
      date = 1.day.ago
      pc = FactoryBot.create(:payment_code, redeemed_at: date)
      rows = CSV.parse(described_class.call.outputs.csv)
      expect(rows[0]).to eq(['Code',
                             'Redeemed At',
                             'Course UUID',
                             'Student Tutor ID',
                             'Student Identifier'])
      expect(rows[1]).to eq ([pc.code,
                              date.to_s,
                              pc.student.course.id.to_s,
                              pc.student.id.to_s,
                              pc.student.student_identifier])
    end

    it 'can filter by a beginning date' do
      older_code = FactoryBot.create(:payment_code, created_at: 3.days.ago).code
      newer_code = FactoryBot.create(:payment_code, created_at: 1.day.ago).code
      rows = CSV.parse(described_class.call(since: 2.days.ago).outputs.csv)
      expect(rows.length).to eq(2)
      expect(rows[1][0]).to eq(newer_code)

      rows = CSV.parse(described_class.call(since: 4.days.ago).outputs.csv)
      expect(rows.length).to eq(3)
      expect(rows[1][0]).to eq(older_code)
      expect(rows[2][0]).to eq(newer_code)
    end
  end
end
