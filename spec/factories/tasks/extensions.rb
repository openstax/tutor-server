FactoryBot.define do
  factory :tasks_extension, class: '::Tasks::Models::Extension' do
    association :task_plan, factory: :tasks_task_plan
    association :role, factory: :entity_role

    time_zone { task_plan.tasking_plans.first.time_zone }
    due_at    { time_zone.to_tz.now }
    closes_at { task_plan.owner.ends_at - 1.day }
  end
end
