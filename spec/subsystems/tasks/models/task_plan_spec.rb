require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, type: :model do
  subject(:task_plan) { FactoryGirl.create :tasks_task_plan }

  let!(:new_task) { FactoryGirl.build :tasks_task, opens_at: Time.now }

  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:tasking_plans) }

  it "validates settings against the assistant's schema" do
    task_plan.assistant = FactoryGirl.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::IReadingAssistant'
    )
    task_plan.settings = { exercise_ids: [1, 2, 3] }.to_json
    expect(task_plan).not_to be_valid
  end

  it 'allows name and description to be updated after a task is open' do
    task_plan.tasks << new_task
    task_plan.title = 'New Title'
    task_plan.description = 'New description!'
    expect(task_plan).to be_valid
  end

  it 'will not allow other fields to be updated after a task is open' do
    task_plan.tasks << new_task
    task_plan.settings = { due_at: Time.now }.to_json
    expect(task_plan).not_to be_valid
  end
end
