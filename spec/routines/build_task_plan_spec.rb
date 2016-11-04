require 'rails_helper'

RSpec.describe BuildTaskPlan, type: :routine do
  let(:course)    { CourseProfile::Models::Course.new }
  let(:assistant) { FactoryGirl.create :tasks_assistant }

  it 'initializes but does not save a TaskPlan object' do
    task_plan = BuildTaskPlan.call(course: course, assistant: assistant).outputs.task_plan

    expect(task_plan).not_to be_persisted
    expect(task_plan.tasking_plans).to be_empty
    expect(task_plan.owner).to eq course
    expect(task_plan.assistant).to eq assistant
  end
end
