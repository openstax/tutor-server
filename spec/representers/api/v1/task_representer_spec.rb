require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do
  let(:ecosystem)      { FactoryGirl.build(:content_ecosystem) }

  let(:task) {FactoryGirl.create(:tasks_task, ecosystem: ecosystem)}

  it 'includes the last_worked_at property' do
    time = Time.current
    formatted_time = DateTimeUtilities.to_api_s(time)

    task.set_last_worked_at(time: time)
    task.save

    represented = described_class.new(task).to_hash

    expect(represented).to include('last_worked_at' => formatted_time)
  end

  it 'includes ecosystem information in the spy' do
    represented = described_class.new(task).to_hash
    # the factory uses lipsum for title so just check for words
    expect(represented['spy']).to eq({ecosystem_id: ecosystem.id,
                                      ecosystem_title: ecosystem.title})
  end

  it 'includes feedback availability' do
    task.feedback_at = nil
    expect(described_class.new(task).to_hash).to include('is_feedback_available' => false)
    task.feedback_at = Time.now - 1.second
    expect(described_class.new(task).to_hash).to include('is_feedback_available' => true)
  end

end
