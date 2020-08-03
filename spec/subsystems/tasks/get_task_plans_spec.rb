require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTaskPlans, type: :routine do
  let!(:task_plan_1) { FactoryBot.create :tasked_task_plan }
  let(:course)       { task_plan_1.course }
  let!(:task_plan_2) { FactoryBot.create :tasks_task_plan, course: course }
  let!(:task_plan_3) { FactoryBot.create :tasks_task_plan, course: course }

  it 'gets all task_plans in a course' do
    out = described_class.call(course: course).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_nil
  end

  it 'does not return withdrawn task_plans' do
    task_plan_2.destroy
    out = described_class.call(course: course).outputs
    expect(out[:plans].length).to eq 2
    expect(out[:plans]).to include(task_plan_1, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_nil
  end
end
