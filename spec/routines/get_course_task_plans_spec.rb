require 'rails_helper'

RSpec.describe GetCourseTaskPlans, type: :routine do
  let!(:course)      { CreateCourse[name: 'Unnamed'] }
  let!(:task_plan_1) { FactoryGirl.create :tasks_task_plan, owner: course }
  let!(:task_plan_2) { FactoryGirl.create :tasks_task_plan, owner: course }
  let!(:task_plan_3) { FactoryGirl.create :tasks_task_plan, owner: course }

  it 'gets all task_plans in a course' do
    out = GetCourseTaskPlans.call(course: course).outputs
    expect(out[:total_count]).to eq 3
    expect(out[:items]).to include(task_plan_1, task_plan_2, task_plan_3)
  end
end
