require 'rails_helper'

RSpec.describe Api::V1::Metatasks::TaskedExerciseRepresenter, type: :representer do
  let(:task_step) { FactoryBot.build(:tasks_tasked_exercise).task_step }
  let(:expected_json) do
    {
      type: 'exercise',
      is_completed: false,
      content_preview: task_step.tasked.content_preview
    }.stringify_keys
  end

  subject(:tasked_representer) do
    Api::V1::Metatasks::TaskedExerciseRepresenter.new(task_step.tasked)
  end

  it 'should represent a tasked exercise' do
    expect(JSON.parse(tasked_representer.to_json)).to include(expected_json)
  end
end
