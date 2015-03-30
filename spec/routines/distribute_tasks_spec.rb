require 'rails_helper'

RSpec.describe DistributeTasks, :type => :routine do
  it 'validates the task_plan settings against the assistant schema' do
    task_plan = FactoryGirl.create :tasks_task_plan

    expect(DistributeTasks.call(task_plan).errors).to be_empty

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

    result = DistributeTasks.call(task_plan)
    expect(result.errors.first.code).to eq :invalid_settings
    expect(result.outputs.tasks).to be_blank
  end

  it "calls the distribute_tasks method on the task_plan's assistant" do
    user = FactoryGirl.create :user
    task_plan = FactoryGirl.create(:tasking_plan, target: user).task_plan

    expect(DummyAssistant).to receive(:distribute_tasks).with(
      task_plan: task_plan, taskees: [user]
    )

    result = DistributeTasks.call(task_plan)
    expect(result.errors).to be_empty
  end
end
