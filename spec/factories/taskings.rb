FactoryGirl.define do
  factory :tasking do
    association :assignee, factory: :student
    task
    user { assignee.user }
  end
end
