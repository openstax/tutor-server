FactoryGirl.define do
  factory :tasking_plan do
    association :target, factory: :klass
    task_plan
  end
end
