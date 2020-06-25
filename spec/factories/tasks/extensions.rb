FactoryBot.define do
  factory :tasks_extension, class: '::Tasks::Models::Extension' do
    association :task_plan, factory: :tasks_task_plan
    association :role, factory: :entity_role

    due_at    { time_zone.now }
    closes_at { task_plan.course.ends_at - 1.day }
  end
end
