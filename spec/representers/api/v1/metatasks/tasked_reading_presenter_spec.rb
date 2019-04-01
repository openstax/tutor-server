require 'rails_helper'

RSpec.describe Api::V1::Metatasks::TaskedReadingRepresenter, type: :representer do
  let(:task_step) { FactoryBot.build(:tasks_tasked_reading).task_step }

  let(:expected_json) do
    {
      is_completed: false,
      content_preview: 'Unknown',
      type: 'reading',
    }.stringify_keys
  end

  subject(:tasked_representer) do
    Api::V1::Metatasks::TaskedReadingRepresenter.new(task_step.tasked)
  end

  it "has the correct 'placeholder_for'" do
    expect(JSON.parse(tasked_representer.to_json)).to include(expected_json)
  end
end
