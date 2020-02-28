require 'rails_helper'

RSpec.describe CreatePeriod, type: :routine do
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:time_zone)     { course.time_zone.to_tz }
  let!(:period)       { described_class[course: course, name: 'Original period'] }
  let!(:other_period) { described_class[course: course, name: 'Other period'] }

  let(:new_period)    { described_class[course: course, name: 'New period'] }
  let(:task_plan_ids) { Tasks::Models::TaskPlan.joins(:tasking_plans)
                          .preload(:tasking_plans)
                          .where(tasking_plans: {
                            target_id: new_period.id,
                            target_type: 'CourseMembership::Models::Period'
                          })
                          .map(&:id) }

  it 'copies existing "coursewide" task plans to the new period' do
    Timecop.freeze do
      expected = FactoryBot.build(:tasks_task_plan, owner: course, num_tasking_plans: 0)

      FactoryBot.create(:tasks_tasking_plan, task_plan: expected,
                                              opens_at: time_zone.now,
                                              due_at: time_zone.now.tomorrow,
                                              target: period)

      FactoryBot.create(:tasks_tasking_plan, task_plan: expected,
                                              opens_at: time_zone.now,
                                              due_at: time_zone.now.tomorrow,
                                              target: other_period)

      expect(task_plan_ids).to include(expected.id)
    end
  end

  it 'does not copy task plans not applied to all periods' do
    Timecop.freeze do
      single_period = FactoryBot.build(:tasks_task_plan, owner: course, num_tasking_plans: 0)

      FactoryBot.create(:tasks_tasking_plan, task_plan: single_period, target: period)

      expect(task_plan_ids).not_to include(single_period.id)
    end
  end

  it 'does not copy task plans across all periods with mismatching due dates' do
    Timecop.freeze do
      diff_due_dates = FactoryBot.build(:tasks_task_plan, owner: course, num_tasking_plans: 0)

      FactoryBot.create(:tasks_tasking_plan, task_plan: diff_due_dates,
                                              opens_at: time_zone.now,
                                              due_at: time_zone.now.tomorrow,
                                              target: period)

      FactoryBot.create(:tasks_tasking_plan, task_plan: diff_due_dates,
                                              opens_at: time_zone.now,
                                              due_at: time_zone.now + 1.minute,
                                              target: other_period)

      expect(task_plan_ids).not_to include(diff_due_dates.id)
    end
  end

  it 'does not copy task plans across all periods with mismatching open dates' do
    Timecop.freeze do
      diff_open_dates = FactoryBot.build(:tasks_task_plan, owner: course, num_tasking_plans: 0)

      FactoryBot.create(:tasks_tasking_plan, task_plan: diff_open_dates,
                                              opens_at: time_zone.now,
                                              due_at: time_zone.now + 2.minutes,
                                              target: period)

      FactoryBot.create(:tasks_tasking_plan, task_plan: diff_open_dates,
                                              opens_at: time_zone.now + 1.minute,
                                              due_at: time_zone.now + 2.minutes,
                                              target: other_period)

      expect(task_plan_ids).not_to include(diff_open_dates.id)
    end
  end
end
