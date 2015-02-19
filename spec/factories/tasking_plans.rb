FactoryGirl.define do
  factory :tasking_plan do
    association :target, factory: :course
    task_plan
  end
end
