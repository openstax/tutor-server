require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::TaskPlan::StatsRepresenter, type: :representer do
  let(:number_of_students) { 2 }

  let(:task_plan)          do
    FactoryBot.create :tasked_task_plan, number_of_students: number_of_students
  end

  let(:representation)     { described_class.new(task_plan).as_json.deep_symbolize_keys }

  it 'represents a task plan with stats' do
    expect(representation).to include(
      id: task_plan.id.to_s,
      title: task_plan.title,
      type: 'reading',
      stats: [
        {
          period_id: task_plan.course.periods.first.id.to_s,
          name: '1st',
          total_count: 2,
          complete_count: 0,
          partially_complete_count: 0
        }
      ]
    )
  end

  context 'shareable_url' do
    it 'can be read' do
      FactoryBot.create :short_code_short_code, code: 'short', uri: task_plan.to_global_id.to_s
      allow(task_plan).to receive(:title).and_return('Read ch 4')
      expect(representation[:shareable_url]).to eq '/@/short/read-ch-4'
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        described_class.new(task_plan).from_json({
          shareable_url: 'http://www.example.org'
        }.to_json)
      end.not_to change { described_class.new(task_plan).as_json }
    end
  end
end
