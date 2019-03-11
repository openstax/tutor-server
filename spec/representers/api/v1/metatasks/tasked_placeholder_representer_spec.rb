require 'rails_helper'

RSpec.describe Api::V1::Metatasks::TaskedPlaceholderRepresenter, type: :representer do
  let(:task_step) { FactoryBot.build(:tasks_tasked_placeholder).task_step }

  let(:expected_json) do
    {
      is_completed: false,
      placeholder_for: "unknown_type",
      type: "placeholder"
    }.stringify_keys
  end

  subject(:tasked_representer) do
    Api::V1::Metatasks::TaskedPlaceholderRepresenter.new(task_step.tasked)
  end

  it "has the correct 'placeholder_for'" do
    expect(JSON.parse(tasked_representer.to_json)).to include(expected_json)
  end
end
