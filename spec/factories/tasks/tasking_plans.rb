FactoryGirl.define do
  factory :tasks_tasking_plan, class: '::Tasks::Models::TaskingPlan' do
    transient do
      duration 1.week
    end

    association :target, factory: :entity_course
    association :task_plan, factory: :tasks_task_plan

    opens_at { Time.now }
    due_at   { opens_at + duration }
  end
end
