require 'rails_helper'

RSpec.describe DistributeTasks, :type => :routine do
  it 'validates the task_plan settings against the assistant schema' do
    task_plan = FactoryGirl.create :task_plan

    expect(DistributeTasks.call(task_plan).errors).to be_empty

    allow(DummyAssistant).to receive(:schema).and_return(
      '{
        "type": "object",
        "required": [
          "page_id"
        ],
        "properties": {
          "page_id": {
            "type": "integer"
          }
        },
        "additionalProperties": false
      }'
    )
    expect(DistributeTasks.call(task_plan).errors.first.code).to(
      eq :invalid_settings
    )
  end

  it "calls the distribute_tasks method on the task_plan's assistant" do
    user = FactoryGirl.create :user
    task_plan = FactoryGirl.create(:tasking_plan, target: user).task_plan

    expect(DummyAssistant).to receive(:distribute_tasks).with(
      task_plan: task_plan, taskees: [user]
    )
    DistributeTasks.call(task_plan)
  end
end
