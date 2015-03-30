FactoryGirl.define do
  factory :tasks_tasking_plan, class: '::Tasks::Models::TaskingPlan' do
    association :target, factory: :course
    task_plan
  end
end
