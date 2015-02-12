class EmptyClass; end

FactoryGirl.define do
  factory :assistant do
    name { Faker::Name.name }
    code_class_name "Dummy"
    task_plan_type "dummy"
  end
end
