require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do
  context 'unpublished task_plan' do
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
      expect(DummyAssistant).not_to receive(:distribute_tasks)

      result = DistributeTasks.call(task_plan)
      expect(result.errors.first.code).to eq :invalid_settings
      expect(task_plan.reload.published_at).to be_nil
      expect(task_plan.tasks).to be_blank
    end

    it "calls the distribute_tasks method on the task_plan's assistant" do
      expect(DummyAssistant).to receive(:distribute_tasks).with(
        task_plan: task_plan,
        taskees: [Role::GetDefaultUserRole[user.entity_user]]
      )

      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
    end

    it "sets the published_at field" do
      DistributeTasks.call(task_plan)
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end

  context 'published task_plan' do
    let!(:user)      { FactoryGirl.create :user_profile }
    let!(:task_plan) {
      tp = FactoryGirl.create(:tasks_tasking_plan, target: user).task_plan
      DistributeTasks.call(tp)
      tp.reload
    }

    it 'validates the task_plan settings against the assistant schema' do
      previous_published_at = task_plan.published_at
      previous_tasks = task_plan.tasks

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
      expect(DummyAssistant).not_to receive(:distribute_tasks)

      result = DistributeTasks.call(task_plan)
      expect(result.errors.first.code).to eq :invalid_settings
      expect(task_plan.reload.published_at).to eq previous_published_at
      expect(task_plan.tasks).to eq previous_tasks
    end

    it "calls the distribute_tasks method on the task_plan's assistant" do
      expect(DummyAssistant).to receive(:distribute_tasks).with(
        task_plan: task_plan,
        taskees: [Role::GetDefaultUserRole[user.entity_user]]
      )

      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
    end

    it "sets the published_at field" do
      DistributeTasks.call(task_plan)
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end
end
