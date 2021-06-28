require 'rails_helper'

RSpec.describe GeneratePaymentCodeReport, type: :routine do
  context 'when generating a report on code use' do
    it 'exports a csv with codes and other data' do
      date = 1.day.ago
      pc = FactoryBot.create(:payment_code, redeemed_at: date)
      path = described_class.call.outputs.export_path
      expect(File.exist?(path)).to be(true)
      expect(path.ends_with? '.csv').to be(true)
      rows = CSV.read(path)
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
  end
end
