require 'rails_helper'

RSpec.describe CheckValidSettings do
  let!(:user)      { FactoryGirl.create :user_profile }
  let!(:task_plan) { FactoryGirl.create(:tasks_tasking_plan, target: user).task_plan }

  it 'validates the task_plan settings against the assistant schema' do
    allow(DummyAssistant).to receive(:schema).and_return(
      '{
        "type": "object",
        "required": [
          "page_ids"
        ],
        "properties": {
          "page_ids": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          }
        },
        "additionalProperties": false
      }'
    )
    result = CheckValidSettings[validatable: task_plan]
    expect(result.errors.code).to eq :invalid_settings
    expect(task_plan.reload.published_at).to be_nil
    expect(task_plan.tasks).to be_blank
  end

end
