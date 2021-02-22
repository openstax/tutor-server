require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTaskPlans, type: :routine do
  let(:ecosystem) { generate_mini_ecosystem }
  let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course) {
    FactoryBot.create :course_profile_course, :with_grading_templates,
                      offering: offering
  }
  let!(:task_plan_1) { FactoryBot.create :tasked_task_plan, ecosystem: ecosystem, course: course }
  let!(:task_plan_2) { FactoryBot.create :tasks_task_plan, ecosystem: ecosystem, course: course }
  let!(:task_plan_3) { FactoryBot.create :tasks_task_plan, ecosystem: ecosystem, course: course }

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
