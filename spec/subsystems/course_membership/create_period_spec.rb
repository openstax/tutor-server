require 'rails_helper'
require 'vcr_helper'

RSpec.describe CourseMembership::CreatePeriod do
  let(:course) { CreateCourse[name: 'Great course'] }
  let(:period) { described_class[course: course, name: 'Cool period'] }

  it 'generates an enrollment_code' do
    allow(Babbler).to receive(:babble) { 'formidableWalrus' }
    expect(period.enrollment_code).to eq('formidableWalrus')
  end

  it 'copies existing "whole course" task plans to the new period' do
    other_period = described_class[course: course, name: 'Other period']

    task_plan = FactoryGirl.build(
      :tasks_task_plan,
      owner: course,
      num_tasking_plans: 0
    )

    expected_tasking_plan = FactoryGirl.create(
      :tasks_tasking_plan,
      task_plan: task_plan,
      target: period.to_model
    )

    other_expected_tasking_plan = FactoryGirl.create(
      :tasks_tasking_plan,
      task_plan: task_plan,
      target: other_period.to_model
    )

    unexpected_tasking_plan = FactoryGirl.create(
      :tasks_tasking_plan,
      task_plan: FactoryGirl.build(:tasks_task_plan, owner: course, num_tasking_plans: 0),
      target: other_period.to_model
    )

    new_period = described_class[course: course, name: 'New period']

    tasking_plan_ids = Tasks::Models::TaskingPlan.where(target: new_period.to_model)
                                                 .collect(&:id)

    expect(tasking_plan_ids).to include(expected_tasking_plan.id)
    expect(tasking_plan_ids).to include(other_expected_tasking_plan.id)
    expect(tasking_plan_ids).not_to include(unexpected_tasking_plan.id)
  end
end
