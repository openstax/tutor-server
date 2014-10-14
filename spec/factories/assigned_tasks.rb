FactoryGirl.define do
  factory :assigned_task do
    association :assignee, factory: :student
    user_id { assignee.user_id }
    task
  end
end
