FactoryGirl.define do
  factory :tasks_tasking_plan, class_name: '::Tasks::Models::TaskingPlan' do
    association :target, factory: :course
    task_plan
  end
end
