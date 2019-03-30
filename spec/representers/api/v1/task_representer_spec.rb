require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do
  let(:ecosystem) { FactoryBot.create(:content_ecosystem) }
  let(:task)      { FactoryBot.create(:tasks_task, ecosystem: ecosystem) }
  let(:represented) { described_class.new(task).to_hash }

  it 'includes fields' do
    expect(represented).to include(
                             'title' => task.title,
                             'type' => task.task_type,
                             'due_at' => DateTimeUtilities.to_api_s(task.due_at),
                           )
  end

  it 'includes ecosystem information in the spy' do
    expect(represented['spy']).to(
      eq({ecosystem_id: ecosystem.id, ecosystem_title: ecosystem.title})
    )
  end

  it 'includes feedback_at feedback availability' do
    task.feedback_at = nil
    expect(described_class.new(task).to_hash['feedback_at']).to be_nil
    task.feedback_at = Time.current.yesterday
    expect(described_class.new(task).to_hash).to include('feedback_at' => DateTimeUtilities.to_api_s(task.feedback_at))
  end

  it 'includes is_deleted' do
    task.task_plan.withdrawn_at = nil
    expect(described_class.new(task).to_hash).to include('is_deleted' => false)
    task.task_plan.withdrawn_at = Time.current.yesterday
    expect(described_class.new(task).to_hash).to include('is_deleted' => true)
    task.task_plan.withdrawn_at = Time.current.tomorrow
    expect(described_class.new(task).to_hash).to include('is_deleted' => true)
  end

end
