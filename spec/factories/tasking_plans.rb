# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tasking_plan do
    association :target, factory: :klass
    task_plan
  end
end
