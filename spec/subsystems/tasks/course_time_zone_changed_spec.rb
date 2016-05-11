require 'rails_helper'

RSpec.describe Tasks::CourseTimeZoneChanged, type: :routine do

  let!(:old_opens_at) { Chronic.parse("2016-07-01 17:01:02 -0700").to_datetime }
  let!(:old_due_at)   { Chronic.parse("2016-07-02 17:01:02 -0700").to_datetime }
  let!(:period)       { ::CreatePeriod[course: Entity::Course.create!] }
  let!(:student)      { FactoryGirl.create(:user) }
  let!(:student_role) { AddUserAsPeriodStudent[user: student, period: period] }
  let!(:task_plan)    { FactoryGirl.create :tasked_task_plan, owner: period.course }
  let!(:tasking_plan) { task_plan.tasking_plans.first.tap do |tp|
                          tp.opens_at = old_opens_at
                          tp.due_at = old_due_at
                          tp.save
                        end }
  let!(:task)         { FactoryGirl.create :tasks_task, opens_at: old_opens_at, due_at: old_due_at }
  let!(:not_due_task) { FactoryGirl.create :tasks_task, due_at: nil }

  before(:each) do
    [task, not_due_task].each do |tt|
      FactoryGirl.create :tasks_tasking, role: student_role, task: tt.entity_task
    end
  end

  it 'changes task plan and task times' do
    described_class[course: period.course,
                    old_time_zone_name: "Pacific Time (US & Canada)",
                    new_time_zone_name: "Central Time (US & Canada)"]

    tasking_plan.reload
    task.reload

    new_opens_at = Chronic.parse("2016-07-01 17:01:02 -0500").to_datetime
    new_due_at = Chronic.parse("2016-07-02 17:01:02 -0500").to_datetime

    expect(tasking_plan.opens_at).to eq new_opens_at
    expect(tasking_plan.due_at).to eq new_due_at
    expect(task.opens_at).to eq new_opens_at
    expect(task.due_at).to eq new_due_at
    expect(not_due_task.due_at).to be_nil
  end

end
