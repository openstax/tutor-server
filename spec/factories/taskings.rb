FactoryGirl.define do
  factory :tasking do
    association :taskee, factory: :user
    task
    user { taskee }
  end
end
