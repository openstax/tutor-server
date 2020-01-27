FactoryBot.define do
  factory :tasks_tasking_plan, class: '::Tasks::Models::TaskingPlan' do
    transient do
      duration { 1.week }
    end

    after(:build) do |tasking_plan, evaluator|
      tasking_plan.task_plan ||= build(:tasks_task_plan, num_tasking_plans: 0)
      tasking_plan.target ||= tasking_plan.task_plan.owner
      tasking_plan.task_plan.tasking_plans << tasking_plan

      tasking_plan.time_zone ||= tasking_plan.task_plan.owner.try(:time_zone) || build(:time_zone)
      tasking_plan.opens_at ||= tasking_plan.time_zone.to_tz.now
      tasking_plan.due_at ||= tasking_plan.opens_at + evaluator.duration
      tasking_plan.closes_at ||= tasking_plan.task_plan.owner.ends_at - 1.day
    end
  end
end
