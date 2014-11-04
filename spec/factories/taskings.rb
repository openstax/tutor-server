FactoryGirl.define do
  factory :tasking do
    association :taskee, factory: :student
    task
    user { taskee.user }
  end
end
