require 'rails_helper'

RSpec.describe DistributeTasks, :type => :routine do
  it 'validates the task_plan settings against the assistant schema' do
    task_plan = FactoryGirl.create :tasks_task_plan

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
    expect(task_plan.published_at).to be_nil
    expect(result.outputs.tasks).to be_blank
  end

  it "calls the distribute_tasks method on the task_plan's assistant" do
    user = FactoryGirl.create :user
    task_plan = FactoryGirl.create(:tasks_tasking_plan, target: user).task_plan

    expect(DummyAssistant).to receive(:distribute_tasks).with(
      task_plan: task_plan, taskees: [Role::GetDefaultUserRole[user.entity_user]]
    )

    result = DistributeTasks.call(task_plan)
    expect(result.errors).to be_empty
  end

  it "sets the published_at field when it distributes" do
      task_plan = FactoryGirl.create :tasks_task_plan
      DistributeTasks.call(task_plan)
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
  end

end
