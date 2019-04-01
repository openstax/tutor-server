require 'rails_helper'

RSpec.describe Api::V1::Metatasks::TaskedExternalUrlRepresenter, type: :representer do
  let(:task_step) { FactoryBot.build(:tasks_tasked_external_url).task_step }
  let(:expected_json) do
    {
      type: 'external_url',
      is_completed: false,
      content_preview: task_step.tasked.title
    }.stringify_keys
  end

  subject(:tasked_representer) do
    Api::V1::Metatasks::TaskedExternalUrlRepresenter.new(task_step.tasked)
  end

  it 'should represent a tasked external url' do
    expect(JSON.parse(tasked_representer.to_json)).to include(expected_json)
  end
end
