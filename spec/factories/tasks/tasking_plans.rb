FactoryGirl.define do
  factory :tasks_tasking_plan, class: '::Tasks::Models::TaskingPlan' do
    transient do
      duration 1.week
    end

    opens_at { Time.now }
    due_at   { opens_at + duration }

    after(:build) do |tasking_plan, evaluator|
      tasking_plan.task_plan ||= build(:tasks_task_plan, num_tasking_plans: 0)
      tasking_plan.target ||= tasking_plan.task_plan.owner
      tasking_plan.task_plan.tasking_plans << tasking_plan
    end
  end
end
