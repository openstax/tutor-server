require 'rails_helper'

RSpec.describe CreatePeriod do
  it 'copies existing "whole course" task plans to the new period' do
    course = CreateCourse[name: 'Great course']
    period = described_class[course: course, name: 'Original period']
    other_period = described_class[course: course, name: 'Other period']
    course.reload # course.periods is cached in the routine

    Timecop.freeze do
      expected = FactoryGirl.build(:tasks_task_plan, owner: course, num_tasking_plans: 0)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: expected,
                                                opens_at: Time.current,
                                                due_at: Time.current + 1.day,
                                                target: period.to_model)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: expected,
                                                opens_at: Time.current,
                                                due_at: Time.current + 1.day,
                                                target: other_period.to_model)

      single_period = FactoryGirl.build(:tasks_task_plan, owner: course,
                                                          num_tasking_plans: 0)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: single_period,
                                                target: period.to_model)

      diff_due_dates = FactoryGirl.build(:tasks_task_plan, owner: course,
                                                           num_tasking_plans: 0)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: diff_due_dates,
                                                opens_at: Time.current,
                                                due_at: Time.current + 1.day,
                                                target: period.to_model)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: diff_due_dates,
                                                opens_at: Time.current,
                                                due_at: Time.current + 1.minute,
                                                target: other_period.to_model)

      diff_open_dates = FactoryGirl.build(:tasks_task_plan, owner: course,
                                                            num_tasking_plans: 0)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: diff_open_dates,
                                                opens_at: Time.current,
                                                due_at: Time.current + 2.minutes,
                                                target: period.to_model)

        FactoryGirl.create(:tasks_tasking_plan, task_plan: diff_open_dates,
                                                opens_at: Time.current + 1.minute,
                                                due_at: Time.current + 2.minutes,
                                                target: other_period.to_model)

      new_period = described_class[course: course, name: 'New period']

      task_plan_ids = Tasks::Models::TaskPlan.joins(:tasking_plans)
                        .preload(:tasking_plans)
                        .where(tasking_plans: {
                          target_id: new_period.id,
                          target_type: 'CourseMembership::Models::Period'
                        })
                        .collect(&:id)

      expect(task_plan_ids).to include(expected.id)
      expect(task_plan_ids).not_to include(single_period.id)
      expect(task_plan_ids).not_to include(diff_due_dates.id)
      expect(task_plan_ids).not_to include(diff_open_dates.id)
    end
  end
end
